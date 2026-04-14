# frozen_string_literal: true

module BankStatements
  # OCR (Mistral) + extração estruturada (OpenAI) para um extrato bancário (PDF).
  class ExtractTransactions
    class Error < StandardError; end

    LLM_MAX_TOKENS = 8192
    MAX_OCR_CHARS_FOR_LLM = (ENV["BANK_STATEMENT_LLM_MAX_OCR_CHARS"] || "120000").to_i.clamp(10_000, 500_000)

    SYSTEM_PROMPT = "Você é um extrator de transações bancárias. Responda somente com JSON válido conforme as instruções do utilizador."

    USER_PROMPT_TEMPLATE = <<~PROMPT
      Você é um extrator de transações bancárias.

      Dado um extrato bancário em qualquer formato, extraia SOMENTE as transações individuais.

      Regras:
      - Ignore linhas de saldo, totais, cabeçalhos e rodapés
      - Valores de débito devem ser negativos, créditos positivos
      - Se a data estiver ausente na linha, use a data do grupo/bloco acima
      - Datas sempre no formato YYYY-MM-DD
      - Valores sempre como número float (ex: -150.00, não "R$ 150,00")
      - Ignore linhas de saldo, totais e cabeçalhos
      - description: texto limpo sem data, sem "PIX", sem "TED" no início — só o que identifica a transação
      - Nunca invente. Nunca omita.

      Retorne SOMENTE JSON válido, sem markdown, sem explicação:
      [
        {
          "date": "2026-04-06",
          "description": "PIX - RENATO GOUVEIA DA SILVA",
          "amount": 500.00,
          "type": "credit"
        }
      ]

      Conteúdo do extrato (markdown OCR):
      %{ocr_body}
    PROMPT

    def self.call(import:)
      new(import).call
    end

    def initialize(import)
      @import = import
    end

    def call
      ocr_result = nil
      raise Error, "Ficheiro em falta" unless @import.file.attached?

      @import.update!(status: :processing)

      ocr_result = ::MistralOcr::ExtractContent.call(attachment: @import.file)
      full_text = ocr_result[:text].to_s
      truncated =
        if full_text.length > MAX_OCR_CHARS_FOR_LLM
          full_text[0, MAX_OCR_CHARS_FOR_LLM]
        else
          full_text
        end

      user_prompt = format(USER_PROMPT_TEMPLATE, ocr_body: truncated)

      raw = ::Openai::Completion.call(
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_prompt }
        ],
        model: ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini"),
        max_tokens: LLM_MAX_TOKENS,
        temperature: 0.1
      )

      parsed = parse_json_array(raw)
      transactions = normalize_transactions(parsed)

      meta = (@import.metadata || {}).dup
      meta["mistral_ocr"] = {
        "model" => ocr_result.dig(:response, "model"),
        "usage_info" => ocr_result.dig(:response, "usage_info"),
        "ocr_char_count" => full_text.length,
        "llm_ocr_char_count" => truncated.length,
        "truncated" => truncated.length < full_text.length
      }.compact

      ocr_stored = full_text.truncate(BankStatementImport::OCR_TEXT_MAX_CHARS)
      now = Time.current

      rows = build_insert_rows(transactions, now)

      BankStatement.transaction do
        @import.bank_statements.delete_all
        BankStatement.insert_all!(rows) if rows.any?
        @import.update!(
          status: :completed,
          ocr_text: ocr_stored,
          metadata: meta
        )
      end

      BankStatementImportEmbeddingRecordsJob.perform_later(@import.id)
      BankStatementWikiIngestJob.perform_later(@import.id)
    rescue ::MistralOcr::ExtractContent::Error, ::Openai::Completion::Error, Error => e
      mark_failed!(e.message, ocr_result: ocr_result)
    rescue JSON::ParserError => e
      mark_failed!("JSON inválido da LLM: #{e.message}", ocr_result: ocr_result)
    rescue StandardError => e
      Rails.logger.error("[BankStatements::ExtractTransactions] #{e.class}: #{e.message}")
      mark_failed!(e.message, ocr_result: ocr_result)
    end

    private

    def build_insert_rows(transactions, now)
      transactions.filter_map do |tx|
        date_str = tx["date"].to_s
        occurred =
          begin
            Date.parse(date_str)
          rescue ArgumentError, TypeError
            next
          end

        description = tx["description"].to_s.strip.squeeze(" ").truncate(500)
        next if description.blank?

        amount_f = tx["amount"]
        ttype = tx["type"].to_s.strip.downcase

        {
          "account_id" => @import.account_id,
          "client_id" => @import.client_id,
          "bank_statement_import_id" => @import.id,
          "institution_id" => @import.institution_id,
          "occurred_on" => occurred,
          "amount" => amount_f,
          "transaction_type" => ttype,
          "description" => description,
          "created_at" => now,
          "updated_at" => now
        }
      end
    end

    def parse_json_array(raw)
      cleaned = raw.to_s.strip.gsub(/\A```(?:json)?\s*/i, "").gsub(/\s*```\z/, "")
      data = JSON.parse(cleaned)
      raise Error, "A LLM deve devolver um array JSON na raiz" unless data.is_a?(Array)

      data
    end

    def normalize_transactions(rows)
      rows.filter_map.with_index do |row, i|
        next unless row.is_a?(Hash)

        date = row["date"].to_s.strip
        description = row["description"].to_s.strip.squeeze(" ")
        amount = row["amount"]
        amount_f =
          case amount
          when Numeric then amount.to_f
          else Float(amount.to_s.tr(",", "."), exception: false)
          end
        type = row["type"].to_s.strip.downcase

        next if date.blank? || description.blank? || amount_f.nil?

        type = "credit" if type.blank? && amount_f >= 0.0
        type = "debit" if type.blank? && amount_f.negative?
        type = "credit" unless %w[credit debit].include?(type)

        {
          "date" => date,
          "description" => description.truncate(500),
          "amount" => amount_f.round(2),
          "type" => type
        }
      rescue ArgumentError, TypeError
        Rails.logger.warn("[BankStatements::ExtractTransactions] linha #{i} ignorada: #{row.inspect}")
        nil
      end
    end

    def mark_failed!(message, ocr_result: nil)
      meta = (@import.metadata || {}).dup
      meta["error"] = { "message" => message, "at" => Time.current.iso8601 }
      if ocr_result.is_a?(Hash) && ocr_result[:response].is_a?(Hash)
        resp = ocr_result[:response]
        meta["mistral_ocr"] = {
          "model" => resp["model"],
          "usage_info" => resp["usage_info"]
        }.compact
      end
      @import.update(status: :failed, metadata: meta)
      @import.wiki_pages.destroy_all
      @import.embedding_records.destroy_all
    end
  end
end

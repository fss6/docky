# frozen_string_literal: true

module Wiki
  # Atualiza a Base de Conhecimento (wiki) a partir do OCR de um extrato bancário.
  # Espelha a lógica de IngestService para documentos, usando +ocr_text+ do import.
  class BankStatementIngestService
    MAX_FULL_TEXT_CHARS = 20_000
    MAX_WIKI_SUMMARY_CHARS = 12_000
    LLM_MAX_TOKENS = 4096

    class Error < StandardError; end

    def initialize(bank_statement_import, account)
      @import = bank_statement_import
      @account = account
    end

    def call
      schema = @account.wiki_schema&.effective_instructions || WikiSchema::DEFAULT_INSTRUCTIONS
      full_text = extract_text
      return if full_text.blank?

      wiki_summary = existing_wiki_summary

      prompt = build_prompt(schema, full_text, wiki_summary)
      result = call_llm(prompt)
      parsed = parse_json(result)
      parsed ||= {}

      persist_wiki_changes(parsed)
      ensure_import_summary_page(full_text)
      ensure_account_index_page
      log_operation(:ingest, details: { bank_statement_import_id: @import.id, llm: result })
    rescue Error => e
      Rails.logger.error("[Wiki::BankStatementIngestService] #{e.class}: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[Wiki::BankStatementIngestService] unexpected: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    end

    private

    def extract_text
      @import.ocr_text.to_s.truncate(MAX_FULL_TEXT_CHARS)
    end

    def existing_wiki_summary
      pages = @account.wiki_pages.select(:slug, :title, :page_type).ordered
      return "Nenhuma página wiki ainda." if pages.empty?

      pages.map { |p| "- [#{p.page_type}] #{p.slug}: #{p.title}" }.join("\n").truncate(MAX_WIKI_SUMMARY_CHARS)
    end

    def build_prompt(schema, full_text, wiki_summary)
      label = import_label

      <<~PROMPT
        #{schema}

        Novo extrato bancário (texto OCR) recebido: #{label}
        ---
        #{full_text}
        ---

        Wiki atual do account (páginas existentes):
        #{wiki_summary}

        Responda SOMENTE em JSON válido com esta estrutura (sem markdown, sem ```json).
        Regras obrigatórias:
        - Sempre inclua 1 página de summary sobre este extrato em new_pages OU updated_pages (ex.: slug sob "extratos/...").
        - Sempre inclua/atualize a página de índice geral (slug: "index/geral").
        - Não retorne arrays nulos; use [] quando vazio.
        {
          "new_pages": [
            { "slug": "...", "title": "...", "content": "...", "page_type": "summary|entity|synthesis|index" }
          ],
          "updated_pages": [
            { "slug": "...", "content_patch": "..." }
          ],
          "links": [
            { "source_slug": "...", "target_slug": "...", "link_type": "references|contradicts|extends|supersedes" }
          ],
          "contradictions": [
            { "description": "...", "page_slug": "..." }
          ]
        }
      PROMPT
    end

    def import_label
      parts = []
      parts << (@import.file&.attached? ? @import.file.filename.to_s : "extrato ##{@import.id}")
      parts << "Instituição: #{@import.institution&.name}" if @import.institution
      parts << "Cliente: #{@import.client&.name}" if @import.client
      parts.join(" · ")
    end

    def call_llm(prompt)
      messages = [
        { role: "system", content: "Você é um assistente especializado em extratos e documentos financeiros. Responda sempre em JSON válido conforme solicitado." },
        { role: "user",   content: prompt }
      ]
      Openai::Completion.call(
        messages: messages,
        model: ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini"),
        max_tokens: LLM_MAX_TOKENS,
        temperature: 0.2
      )
    end

    def parse_json(raw)
      cleaned = raw.to_s.strip.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
      JSON.parse(cleaned)
    rescue JSON::ParserError => e
      Rails.logger.error("[Wiki::BankStatementIngestService] JSON inválido: #{e.message}. Raw: #{raw.to_s.truncate(500)}")
      nil
    end

    def persist_wiki_changes(parsed)
      ActiveRecord::Base.transaction do
        create_new_pages(parsed["new_pages"] || [])
        update_existing_pages(parsed["updated_pages"] || [])
        create_links(parsed["links"] || [])
        annotate_contradictions(parsed["contradictions"] || [])
      end
    end

    def ensure_import_summary_page(full_text)
      slug = "extratos/import-#{@import.id}-#{slugify(import_title)}"
      page = @account.wiki_pages.find_or_initialize_by(slug: slug)
      return if page.persisted? && page.content.present?

      page.assign_attributes(
        title: import_title,
        page_type: "summary",
        source_document_id: nil,
        source_bank_statement_import_id: @import.id,
        content: full_text.truncate(2500)
      )
      page.save!
    end

    def ensure_account_index_page
      summary_pages = @account.wiki_pages.by_type("summary").order(updated_at: :desc).limit(30)
      body = summary_pages.map { |p| "- #{p.title} (#{p.slug})" }.join("\n")
      body = "Sem páginas de resumo ainda." if body.blank?

      page = @account.wiki_pages.find_or_initialize_by(slug: "index/geral")
      page.assign_attributes(
        title: "Índice Geral",
        page_type: "index",
        content: "## Páginas de resumo\n\n#{body}"
      )
      page.save!
    end

    def create_new_pages(new_pages)
      new_pages.each do |attrs|
        slug = attrs["slug"].to_s.strip
        next if slug.blank?

        page = @account.wiki_pages.find_or_initialize_by(slug: slug)
        page.assign_attributes(
          title: attrs["title"].to_s.strip.presence || slug,
          content: attrs["content"].to_s,
          page_type: sanitize_page_type(attrs["page_type"]),
          source_document_id: nil,
          source_bank_statement_import_id: @import.id
        )
        page.save!
      end
    end

    def update_existing_pages(updated_pages)
      updated_pages.each do |attrs|
        slug = attrs["slug"].to_s.strip
        patch = attrs["content_patch"].to_s.strip
        next if slug.blank? || patch.blank?

        page = @account.wiki_pages.find_by(slug: slug)
        next unless page

        updated_content = "#{page.content}\n\n#{patch}".strip
        page.update!(content: updated_content)
      end
    end

    def create_links(links)
      links.each do |link_attrs|
        source = @account.wiki_pages.find_by(slug: link_attrs["source_slug"].to_s)
        target = @account.wiki_pages.find_by(slug: link_attrs["target_slug"].to_s)
        next unless source && target
        next if source.id == target.id

        WikiLink.find_or_create_by!(
          source_page: source,
          target_page: target
        ) do |l|
          l.link_type = sanitize_link_type(link_attrs["link_type"])
        end
      end
    end

    def annotate_contradictions(contradictions)
      contradictions.each do |c|
        description = c["description"].to_s.strip
        page_slug   = c["page_slug"].to_s.strip
        next if description.blank?

        page = @account.wiki_pages.find_by(slug: page_slug)
        if page
          note = "\n\n**⚠ Contradição detectada:** #{description}"
          page.update_columns(content: page.content.to_s + note, updated_at: Time.current)
        end

        WikiLog.create!(
          account: @account,
          operation: "ingest",
          document_id: nil,
          details: {
            type: "contradiction",
            bank_statement_import_id: @import.id,
            description: description,
            page_slug: page_slug
          }.to_json
        )
      end
    end

    def sanitize_page_type(raw)
      WikiPage::PAGE_TYPES.include?(raw.to_s) ? raw.to_s : "summary"
    end

    def sanitize_link_type(raw)
      WikiLink::LINK_TYPES.include?(raw.to_s) ? raw.to_s : nil
    end

    def import_title
      if @import.file&.attached?
        @import.file.filename.to_s
      else
        "Extrato ##{@import.id}"
      end
    end

    def slugify(text)
      text.to_s.parameterize.presence || "extrato"
    end

    def log_operation(operation, details: nil)
      WikiLog.create!(
        account: @account,
        operation: operation.to_s,
        document_id: nil,
        details: details.is_a?(String) ? details : details&.to_json
      )
    end
  end
end

# frozen_string_literal: true

module Wiki
  # Processa um documento recém-indexado e atualiza/cria páginas no wiki do account.
  # Chamado de forma assíncrona via WikiIngestJob após o OCR concluir.
  class IngestService
    MAX_FULL_TEXT_CHARS  = 20_000
    MAX_WIKI_SUMMARY_CHARS = 12_000
    LLM_MAX_TOKENS = 4096

    class Error < StandardError; end

    def initialize(document, account)
      @document = document
      @account  = account
    end

    def call
      schema       = @account.wiki_schema&.effective_instructions || WikiSchema::DEFAULT_INSTRUCTIONS
      full_text    = extract_text
      return if full_text.blank?

      wiki_summary = existing_wiki_summary

      prompt = build_prompt(schema, full_text, wiki_summary)
      result = call_llm(prompt)
      parsed = parse_json(result)
      parsed ||= {}

      persist_wiki_changes(parsed)
      ensure_document_summary_page(full_text)
      ensure_account_index_page
      log_operation(:ingest, document_id: @document.id, details: result)
    rescue Error => e
      Rails.logger.error("[Wiki::IngestService] #{e.class}: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[Wiki::IngestService] unexpected: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    end

    private

    def extract_text
      chunks = @document.embedding_records.ordered_for_display.pluck(:content).compact
      chunks.join("\n\n").truncate(MAX_FULL_TEXT_CHARS)
    end

    def existing_wiki_summary
      pages = @account.wiki_pages.select(:slug, :title, :page_type).ordered
      return "Nenhuma página wiki ainda." if pages.empty?

      pages.map { |p| "- [#{p.page_type}] #{p.slug}: #{p.title}" }.join("\n").truncate(MAX_WIKI_SUMMARY_CHARS)
    end

    def build_prompt(schema, full_text, wiki_summary)
      doc_name = @document.file&.attached? ? @document.file.filename.to_s : "documento ##{@document.id}"

      <<~PROMPT
        #{schema}

        Novo documento recebido: "#{doc_name}"
        ---
        #{full_text}
        ---

        Wiki atual do account (páginas existentes):
        #{wiki_summary}

        Responda SOMENTE em JSON válido com esta estrutura (sem markdown, sem ```json).
        Regras obrigatórias:
        - Sempre inclua 1 página de summary para este documento em new_pages OU updated_pages.
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

    def call_llm(prompt)
      messages = [
        { role: "system", content: "Você é um assistente especializado em análise de documentos. Responda sempre em JSON válido conforme solicitado." },
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
      Rails.logger.error("[Wiki::IngestService] JSON inválido: #{e.message}. Raw: #{raw.to_s.truncate(500)}")
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

    def ensure_document_summary_page(full_text)
      slug = "documentos/#{@document.id}-#{slugify(document_title)}"
      page = @account.wiki_pages.find_or_initialize_by(slug: slug)
      return if page.persisted? && page.content.present?

      page.assign_attributes(
        title: document_title,
        page_type: "summary",
        source_document_id: @document.id,
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
          title:              attrs["title"].to_s.strip.presence || slug,
          content:            attrs["content"].to_s,
          page_type:          sanitize_page_type(attrs["page_type"]),
          source_document_id: @document.id
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
          document_id: @document.id,
          details: { type: "contradiction", description: description, page_slug: page_slug }.to_json
        )
      end
    end

    def sanitize_page_type(raw)
      WikiPage::PAGE_TYPES.include?(raw.to_s) ? raw.to_s : "summary"
    end

    def sanitize_link_type(raw)
      WikiLink::LINK_TYPES.include?(raw.to_s) ? raw.to_s : nil
    end

    def document_title
      @document.file&.attached? ? @document.file.filename.to_s : "Documento ##{@document.id}"
    end

    def slugify(text)
      text.to_s.parameterize.presence || "documento"
    end

    def log_operation(operation, document_id: nil, wiki_page_id: nil, details: nil)
      WikiLog.create!(
        account: @account,
        operation: operation.to_s,
        document_id: document_id,
        wiki_page_id: wiki_page_id,
        details: details.is_a?(String) ? details : details&.to_json
      )
    end
  end
end

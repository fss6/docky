# frozen_string_literal: true

module Wiki
  # Remove conhecimento derivado de um documento excluído e recompõe o índice.
  class CleanupDocumentService
    def initialize(account:, document_id:)
      @account = account
      @document_id = document_id
    end

    def call
      ActiveRecord::Base.transaction do
        @account.wiki_pages.where(source_document_id: @document_id).find_each(&:destroy!)
        cleanup_orphan_knowledge_pages!
        rebuild_index_page
      end
    end

    private

    def rebuild_index_page
      summary_pages = @account.wiki_pages.by_type("summary").order(updated_at: :desc).limit(30)
      body = summary_pages.map { |p| "- #{p.title} (#{p.slug})" }.join("\n")
      body = "Sem páginas de resumo ainda." if body.blank?

      page = @account.wiki_pages.find_or_initialize_by(slug: "index/geral")
      page.assign_attributes(
        title: "Índice Geral",
        page_type: "index",
        source_document_id: nil,
        content: "## Páginas de resumo\n\n#{body}"
      )
      page.save!
    end

    def cleanup_orphan_knowledge_pages!
      @account.wiki_pages.where(page_type: %w[entity synthesis]).find_each do |page|
        next if page.incoming_links.exists? || page.outgoing_links.exists?
        next if source_document_still_exists?(page)

        page.destroy!
      end
    end

    def source_document_still_exists?(page)
      return false if page.source_document_id.blank?

      @account.documents.where(id: page.source_document_id).exists?
    end
  end
end

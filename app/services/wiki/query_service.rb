# frozen_string_literal: true

module Wiki
  # Enriquece o contexto de uma pergunta com conhecimento acumulado do wiki.
  # Retorna um hash { wiki_chunks:, doc_chunks:, statement_chunks: } para o prompt (RAG).
  class QueryService
    def initialize(question, account, options = {})
      @question     = question
      @account      = account
      @document_ids = options[:document_ids]
    end

    def call
      results = RagSearchService.new(
        @question,
        @account,
        mode: :unified,
        limit: 10,
        document_ids: @document_ids
      ).call

      wiki_chunks = results.select { |r| r.recordable_type == "WikiPage" }
      doc_chunks  = results.select { |r| r.recordable_type == "Document" }
      statement_chunks = results.select { |r| r.recordable_type == "BankStatementImport" }

      log_query(wiki_chunks)

      { wiki_chunks: wiki_chunks, doc_chunks: doc_chunks, statement_chunks: statement_chunks }
    rescue Openai::Embeddings::MissingApiKeyError, Openai::Embeddings::Error
      { wiki_chunks: [], doc_chunks: [], statement_chunks: [] }
    end

    private

    def log_query(wiki_chunks)
      slugs = wiki_chunks.filter_map { |r| r.metadata&.dig("slug") }
      WikiLog.create!(
        account: @account,
        operation: "query",
        details: { question: @question.truncate(500), wiki_pages_used: slugs }.to_json
      )
    rescue StandardError => e
      Rails.logger.warn("[Wiki::QueryService] log failed: #{e.message}")
    end
  end
end

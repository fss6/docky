# frozen_string_literal: true

# Busca unificada em embedding_records: Document, WikiPage e extratos (BankStatementImport).
class RagSearchService
  MODES = %i[unified wiki_only docs_only].freeze
  DEFAULT_LIMIT = 10

  def initialize(question, account, options = {})
    @question = question.to_s.strip
    @account  = account
    @mode     = options[:mode] || :unified
    @limit    = (options[:limit] || DEFAULT_LIMIT).to_i
    @document_ids = Array(options[:document_ids]).compact.map(&:to_i).presence
  end

  def call
    raise ArgumentError, "question em branco" if @question.blank?

    model = ENV.fetch("OPENAI_EMBEDDING_MODEL", Openai::Embeddings::DEFAULT_MODEL)
    query_vec = Openai::Embeddings.call(texts: [@question.truncate(8000)], model: model).first

    scope = EmbeddingRecord
      .where(account_id: @account.id)
      .where.not(embedding: nil)

    scope = filter_by_mode(scope)
    scope = scope.where(document_id: @document_ids) if @document_ids.present? && @mode != :wiki_only

    scope
      .nearest_neighbors(:embedding, query_vec, distance: "cosine")
      .limit(@limit)
      .includes(:recordable)
  end

  private

  def filter_by_mode(scope)
    case @mode
    when :wiki_only  then scope.where(recordable_type: "WikiPage")
    when :docs_only
      scope.where(recordable_type: %w[Document BankStatementImport])
    else scope
    end
  end
end

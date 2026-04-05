# frozen_string_literal: true

module Rag
  # Recupera trechos mais próximos da pergunta (mesma ideia do passo [4b–c] em CHAT_RAG.md).
  class Retrieve
    DEFAULT_LIMIT = 5

    def self.call(account_id:, question:, document_id: nil, document_ids: nil, limit: DEFAULT_LIMIT)
      new(
        account_id: account_id,
        question: question,
        document_id: document_id,
        document_ids: document_ids,
        limit: limit
      ).call
    end

    def initialize(account_id:, question:, document_id: nil, document_ids: nil, limit: DEFAULT_LIMIT)
      @account_id = account_id
      @question = question.to_s.strip
      @document_id = document_id
      ids = Array(document_ids).compact.map(&:presence).compact.uniq
      @document_ids = ids.presence
      @limit = limit.to_i.positive? ? limit.to_i : DEFAULT_LIMIT
    end

    def call
      raise ArgumentError, "question em branco" if @question.blank?

      model = ENV.fetch("OPENAI_EMBEDDING_MODEL", Openai::Embeddings::DEFAULT_MODEL)
      query_vec = ::Openai::Embeddings.call(texts: [@question.truncate(8000)], model: model).first

      scope = ::EmbeddingRecord
        .where(account_id: @account_id)
        .where.not(embedding: nil)

      if @document_ids.present?
        scope = scope.where(document_id: @document_ids)
      elsif @document_id.present?
        scope = scope.where(document_id: @document_id)
      end

      scope.nearest_neighbors(:embedding, query_vec, distance: "cosine").limit(@limit)
    end
  end
end

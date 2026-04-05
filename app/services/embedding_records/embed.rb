# frozen_string_literal: true

module EmbeddingRecords
  # Atualiza coluna `embedding` (e metadados) para registros já com `content`.
  class Embed
    BATCH_SIZE = (ENV["OPENAI_EMBEDDING_BATCH_SIZE"] || "20").to_i.clamp(1, 100)

    def self.call(records)
      new(records).call
    end

    def initialize(records)
      @records = Array(records).compact
    end

    def call
      return if @records.empty?
      return if ENV["OPENAI_API_KEY"].to_s.blank?

      pending = @records.select { |r| r.content.present? && r.embedding.nil? }
      return if pending.empty?

      model = ENV.fetch("OPENAI_EMBEDDING_MODEL", Openai::Embeddings::DEFAULT_MODEL)
      now = Time.current.iso8601

      pending.each_slice(BATCH_SIZE) do |slice|
        texts = slice.map(&:content)
        vectors = ::Openai::Embeddings.call(texts: texts, model: model)

        slice.each_with_index do |record, i|
          record.reload
          next if record.embedding.present?

          meta = (record.metadata || {}).dup
          meta["embedding_model"] = model
          meta["embedded_at"] = now

          record.update!(
            embedding: vectors[i],
            metadata: meta
          )
        end
      end
    rescue ::Openai::Embeddings::MissingApiKeyError
      Rails.logger.info("[EmbeddingRecords::Embed] OPENAI_API_KEY ausente; pulando.")
    rescue ::Openai::Embeddings::Error => e
      Rails.logger.error("[EmbeddingRecords::Embed] #{e.class}: #{e.message}")
      raise
    end
  end
end

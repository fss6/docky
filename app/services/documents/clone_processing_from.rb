# frozen_string_literal: true

module Documents
  class CloneProcessingFrom
    def self.call(source:, target:)
      new(source: source, target: target).call
    end

    def initialize(source:, target:)
      @source = source
      @target = target
    end

    def call
      Document.transaction do
        @target.embedding_records.destroy_all

        meta = (@target.metadata || {}).dup
        source_meta = @source.metadata.is_a?(Hash) ? @source.metadata : {}
        meta["mistral_ocr"] = source_meta["mistral_ocr"] if source_meta["mistral_ocr"].present?
        meta["processing_copied_from_document_id"] = @source.id
        meta["processing_copied_at"] = Time.current.iso8601

        @target.update!(
          content: @source.content,
          summary: @source.summary,
          tags: @source.tags,
          metadata: meta,
          status: :processed
        )

        @source.embedding_records.order(:id).each do |record|
          EmbeddingRecord.create!(
            account: @target.account,
            recordable: @target,
            document_id: @target.id,
            content: record.content,
            embedding: record.embedding,
            metadata: (record.metadata || {}).dup
          )
        end
      end

      @target
    end
  end
end

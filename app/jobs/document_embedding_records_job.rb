# frozen_string_literal: true

class DocumentEmbeddingRecordsJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  retry_on ::Openai::Embeddings::Error, wait: :polynomially_longer, attempts: 5

  def perform(document_id)
    document = Document.find(document_id)
    records = document.embedding_records.pending_embedding.order(:id)
    return if records.none?

    ::EmbeddingRecords::Embed.call(records)
  end
end

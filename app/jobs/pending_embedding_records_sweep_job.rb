# frozen_string_literal: true

# Reprocessa registros com texto mas sem vetor (falhas passadas, fila perdida, etc.).
class PendingEmbeddingRecordsSweepJob < ApplicationJob
  queue_as :default

  SWEEP_LIMIT = (ENV["EMBEDDING_SWEEP_LIMIT"] || "100").to_i.clamp(1, 500)

  retry_on ::Openai::Embeddings::Error, wait: :polynomially_longer, attempts: 3

  def perform
    return if ENV["OPENAI_API_KEY"].to_s.blank?

    ids = EmbeddingRecord.pending_embedding.limit(SWEEP_LIMIT).pluck(:id)
    return if ids.empty?

    records = EmbeddingRecord.where(id: ids).order(:id).to_a
    ::EmbeddingRecords::Embed.call(records)
  end
end

# frozen_string_literal: true

class DocumentOcrJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(document_id)
    document = Document.find(document_id)
    return unless document.file.attached?

    document.update!(status: :processing)

    result = ::MistralOcr::ExtractContent.call(document: document)

    meta = (document.metadata || {}).dup
    meta["mistral_ocr"] = {
      "extracted_at" => Time.current.iso8601,
      "model" => result[:response]["model"],
      "usage_info" => result[:response]["usage_info"]
    }.compact

    pages = result[:response]["pages"] || []

    Document.transaction do
      document.embedding_records.destroy_all

      pages.each_with_index do |page_data, fallback_index|
        markdown = page_data["markdown"].to_s
        next if markdown.blank?

        page_number = page_data["index"]
        page_number = fallback_index if page_number.nil?

        ::MistralOcr::ChunkPageMarkdown.call(markdown).each_with_index do |chunk_text, chunk_index|
          EmbeddingRecord.create!(
            account: document.account,
            recordable: document,
            document_id: document.id,
            content: chunk_text,
            metadata: {
              "page" => page_number,
              "chunk_index" => chunk_index,
              "source" => "ocr"
            }
          )
        end
      end

      document.update!(status: :processed, metadata: meta)
    end

    DocumentEmbeddingRecordsJob.perform_later(document.id)
  rescue ::MistralOcr::ExtractContent::Error => e
    mark_failed(document, e.message)
  rescue StandardError => e
    raise e if e.is_a?(ActiveRecord::RecordNotFound)

    Rails.logger.error("[DocumentOcrJob] #{e.class}: #{e.message}")
    mark_failed(document, e.message)
  end

  private

  def mark_failed(document, message)
    meta = (document.metadata || {}).dup
    meta["ocr_error"] = {
      "message" => message,
      "at" => Time.current.iso8601
    }
    document.update!(status: :failed, metadata: meta)
  end
end

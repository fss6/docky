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

    document.update!(
      content: result[:text],
      status: :processed,
      metadata: meta
    )
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

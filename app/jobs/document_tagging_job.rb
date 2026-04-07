# frozen_string_literal: true

class DocumentTaggingJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(document_id)
    document = Document.find(document_id)
    return unless document.processed?
    return unless document.account&.generate_tags_automatically?

    tags = Documents::TagGenerator.call(document)
    return if tags.nil?

    document.update!(tags: tags)
  rescue Openai::Completion::MissingApiKeyError => e
    Rails.logger.warn("[DocumentTaggingJob] #{e.message}")
  rescue Openai::Completion::Error => e
    Rails.logger.error("[DocumentTaggingJob] #{e.class}: #{e.message}")
  end
end

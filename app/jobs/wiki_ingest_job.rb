# frozen_string_literal: true

class WikiIngestJob < ApplicationJob
  queue_as :wiki_processing

  discard_on ActiveRecord::RecordNotFound

  def perform(document_id)
    document = Document.find(document_id)
    account  = document.account

    Wiki::IngestService.new(document, account).call
  end
end

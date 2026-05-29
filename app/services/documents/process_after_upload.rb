# frozen_string_literal: true

module Documents
  class ProcessAfterUpload
    def self.call(document:, file_io: nil)
      new(document: document, file_io: file_io).call
    end

    def initialize(document:, file_io:)
      @document = document
      @file_io = file_io
    end

    def call
      return unless @document.file.attached?

      hash = compute_hash
      @document.update!(content_sha256: hash)

      source = find_processed_source(hash)
      if source
        CloneProcessingFrom.call(source: source, target: @document)
      else
        DocumentOcrJob.perform_later(@document.id)
      end
    end

    private

    def compute_hash
      if @file_io.present?
        ContentFingerprint.from_upload(@file_io)
      else
        ContentFingerprint.from_blob(@document.file.blob)
      end
    end

    def find_processed_source(hash)
      Document
        .where(account_id: @document.account_id, content_sha256: hash, status: :processed)
        .where.not(id: @document.id)
        .order(created_at: :asc)
        .first
    end
  end
end

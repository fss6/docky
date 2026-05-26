# frozen_string_literal: true

module AuditEvents
  class RecordDocumentReceived
    def self.call(document:, user: nil, ip: nil)
      new(document: document, user: user, ip: ip).call
    end

    def initialize(document:, user: nil, ip: nil)
      @document = document
      @user = user
      @ip = ip
    end

    def call
      @document = @document.reload if @document.persisted?

      return if @document.client_id.blank?
      return if @document.period_id.blank? && @document.collection_period.blank?

      period_record = @document.period
      period_key = period_record&.period&.strftime("%Y-%m") ||
        @document.collection_period&.strftime("%Y-%m")
      return if period_key.blank?

      AuditEvents::Recorder.call(
        account: @document.account,
        user: @user,
        event_type: "document.received",
        subject: @document,
        metadata: {
          client_id: @document.client_id,
          period: period_key,
          period_id: period_record&.id,
          document_id: @document.id,
          filename: filename_label,
          upload_source: upload_source,
          ip: @ip
        }.compact
      )
    end

    private

    def filename_label
      return "arquivo" unless @document.file.attached?

      @document.file.filename.to_s
    end

    def upload_source
      source = @document.metadata.is_a?(Hash) ? @document.metadata["upload_source"] : nil
      source.presence || "account_upload"
    end
  end
end

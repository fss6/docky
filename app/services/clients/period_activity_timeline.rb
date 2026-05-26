# frozen_string_literal: true

module Clients
  class PeriodActivityTimeline
    Entry = Struct.new(:at, :actor, :category, :title, :description, keyword_init: true)

    def self.call(client:, period:, period_record: nil, limit: 50)
      new(client: client, period: period, period_record: period_record, limit: limit).call
    end

    def initialize(client:, period:, period_record: nil, limit: 50)
      @client = client
      @period = period.to_date.beginning_of_month
      @period_record = period_record
      @period_key = @period.strftime("%Y-%m")
      @limit = limit
    end

    def call
      audit_entries = audit_events.map { |event| build_from_audit_event(event) }
      documented_ids = audit_events.filter_map { |e| document_id_from_metadata(e.metadata) if e.event_type == "document.received" }
      legacy_entries = legacy_document_entries(exclude_document_ids: documented_ids)

      (audit_entries + legacy_entries)
        .sort_by(&:at)
        .reverse
        .first(@limit)
    end

    private

    def audit_events
      @audit_events ||= AuditEvent
        .where(account_id: @client.account_id)
        .where("metadata ->> 'client_id' = ?", @client.id.to_s)
        .where("metadata ->> 'period' = ?", @period_key)
        .includes(:user)
        .order(created_at: :desc)
        .limit(@limit * 2)
    end

    def legacy_document_entries(exclude_document_ids:)
      return [] unless @period_record

      scope = Document
        .where(client_id: @client.id, period_id: @period_record.id)
        .includes(:user)
        .order(created_at: :desc)
        .limit(@limit)

      scope = scope.where.not(id: exclude_document_ids) if exclude_document_ids.any?

      scope.map { |document| build_from_document(document) }
    end

    def build_from_audit_event(event)
      presenter = PeriodActivityPresenter.new(event)
      Entry.new(
        at: event.created_at,
        actor: presenter.actor_name,
        category: presenter.category,
        title: presenter.title,
        description: presenter.description
      )
    end

    def build_from_document(document)
      source_label = upload_source_label(document)
      filename = document.file.attached? ? document.file.filename.to_s : "arquivo"

      Entry.new(
        at: document.created_at,
        actor: document.user&.name || "Cliente (portal)",
        category: :document,
        title: "Arquivo recebido",
        description: "#{filename} · #{source_label}"
      )
    end

    def upload_source_label(document)
      case document.metadata.is_a?(Hash) ? document.metadata["upload_source"] : nil
      when "public_link" then "via portal"
      when "internal_upload" then "upload manual"
      when "email_forward" then "e-mail forward"
      else "upload na conta"
      end
    end

    def document_id_from_metadata(metadata)
      return nil unless metadata.is_a?(Hash)

      metadata["document_id"] || metadata[:document_id]
    end
  end
end

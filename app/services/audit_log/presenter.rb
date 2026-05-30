# frozen_string_literal: true

module AuditLog
  class Presenter
    def initialize(
      log,
      audit_events_by_id: {},
      audits_by_id: {},
      subject_labels: {}
    )
      @log = log
      @audit_events_by_id = audit_events_by_id
      @audits_by_id = audits_by_id
      @subject_labels = subject_labels
    end

    def created_at
      @log.created_at
    end

    def source
      @log.source
    end

    def actor_name
      @log.actor_name.presence || "Sistema"
    end

    def action_label
      if event?
        event_presenter.title
      else
        audited_changes_formatter.action_label
      end
    end

    def item_label
      key = subject_label_key
      return @subject_labels[key] if key.present? && @subject_labels[key].present?

      fallback_item_label
    end

    def details_summary
      text = details_full
      text.length > 150 ? text.truncate(150) : text
    end

    def details_title
      details_full
    end

    private

    def event?
      @log.source == "event"
    end

    def event_record
      return @event_record if defined?(@event_record)

      @event_record = @audit_events_by_id[@log.row_id.to_i]
    end

    def audit_record
      return @audit_record if defined?(@audit_record)

      @audit_record = @audits_by_id[@log.row_id.to_i]
    end

    def event_presenter
      @event_presenter ||= begin
        event = event_record || build_event_from_log
        AuditEvents::EventPresenter.new(event)
      end
    end

    def build_event_from_log
      metadata = parse_payload(@log.payload)
      AuditEvent.new(
        event_type: @log.verb,
        subject_type: @log.item_type,
        subject_id: @log.item_id,
        metadata: metadata
      )
    end

    def audited_changes_formatter
      @audited_changes_formatter ||= begin
        audit = audit_record
        changes = audit&.audited_changes || @log.payload
        AuditLog::AuditedChangesFormatter.new(
          auditable_type: @log.item_type,
          action: @log.verb,
          audited_changes: changes
        )
      end
    end

    def details_full
      if event?
        event_presenter.description
      else
        audited_changes_formatter.summary
      end
    end

    def subject_label_key
      return nil if @log.item_type.blank? || @log.item_id.blank?

      "#{@log.item_type}:#{@log.item_id}"
    end

    def fallback_item_label
      type_label = AuditLog::SubjectLabelResolver::ITEM_TYPE_LABELS.fetch(
        @log.item_type.to_s,
        @log.item_type
      )
      if @log.item_id.present?
        "#{type_label} ##{@log.item_id}"
      else
        type_label
      end
    end

    def parse_payload(raw)
      return raw if raw.is_a?(Hash)
      return {} if raw.blank?

      JSON.parse(raw.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end

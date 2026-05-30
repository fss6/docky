# frozen_string_literal: true

module Clients
  class PeriodActivityPresenter
    def initialize(audit_event)
      @event = audit_event
      @event_presenter = AuditEvents::EventPresenter.new(audit_event)
    end

    def actor_name
      @event_presenter.actor_name
    end

    def category
      case @event.event_type
      when "document.received" then :document
      when "period.closed", "period.reopened", "period.created_retroactive", "monthly_collection.created" then :period
      when "upload_invite.email_sent" then :email
      when "upload_invite.email_failed" then :email_failed
      when /^upload_invite\./ then :invite
      when /^checklist_item\./ then :checklist
      else :other
      end
    end

    def title
      @event_presenter.title
    end

    def description
      @event_presenter.description
    end
  end
end

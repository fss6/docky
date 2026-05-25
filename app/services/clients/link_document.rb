# frozen_string_literal: true

module Clients
  class LinkDocument
    def self.call(document:, item:, user:, ip: nil)
      new(document: document, item: item, user: user, ip: ip).call
    end

    def initialize(document:, item:, user:, ip: nil)
      @document = document
      @item = item
      @user = user
      @ip = ip
    end

    def call
      raise ArgumentError, "Item já possui documento" if @item.last_document_id.present?

      attrs = {
        last_document: @document,
        received_at: Time.current,
        state: :validated,
        validated_by_user: @user,
        validated_at: Time.current
      }

      if @item.update(attrs)
        invalidate_cache
        record_audit!
        true
      else
        false
      end
    end

    private

    def invalidate_cache
      checklist = @item.competency_checklist
      InvalidateSummaryCache.call(client: checklist.client, period: checklist.period)
    end

    def record_audit!
      checklist = @item.competency_checklist
      AuditEvents::Recorder.call(
        account: checklist.account,
        user: @user,
        event_type: "checklist_item.document_linked",
        subject: @item,
        metadata: {
          document_id: @document.id,
          client_id: checklist.client_id,
          period: checklist.period.strftime("%Y-%m"),
          ip: @ip
        }.compact
      )
    end
  end
end

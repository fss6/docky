# frozen_string_literal: true

module Clients
  class UnlinkDocument
    def self.call(item:, user:, ip: nil)
      new(item: item, user: user, ip: ip).call
    end

    def initialize(item:, user:, ip: nil)
      @item = item
      @user = user
      @ip = ip
    end

    def call
      document_id = @item.last_document_id
      @item.update!(
        last_document: nil,
        received_at: nil,
        state: :pending,
        validated_by_user: nil,
        validated_at: nil
      )
      invalidate_cache
      record_audit!(document_id)
      true
    end

    private

    def invalidate_cache
      checklist = @item.competency_checklist
      InvalidateSummaryCache.call(client: checklist.client, period: checklist.period)
    end

    def record_audit!(document_id)
      checklist = @item.competency_checklist
      AuditEvents::Recorder.call(
        account: checklist.account,
        user: @user,
        event_type: "checklist_item.document_unlinked",
        subject: @item,
        metadata: {
          document_id: document_id,
          client_id: checklist.client_id,
          period: checklist.period.strftime("%Y-%m"),
          item_name: @item.name_snapshot,
          ip: @ip
        }.compact
      )
    end
  end
end

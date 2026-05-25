# frozen_string_literal: true

module Clients
  class MarkChecklistItemValidated
    def self.call(item:, user:, ip: nil)
      new(item: item, user: user, ip: ip).call
    end

    def initialize(item:, user:, ip: nil)
      @item = item
      @user = user
      @ip = ip
    end

    def call
      return true if @item.validated?

      @item.mark_validated!(user: @user)
      invalidate_cache
      record_audit!
      true
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
        event_type: "checklist_item.marked_validated",
        subject: @item,
        metadata: {
          client_id: checklist.client_id,
          period: checklist.period.strftime("%Y-%m"),
          ip: @ip
        }.compact
      )
    end
  end
end

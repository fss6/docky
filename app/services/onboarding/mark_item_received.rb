# frozen_string_literal: true

module Onboarding
  class MarkItemReceived
    def self.call(item:, document: nil, user: nil, account: nil)
      new(item: item, document: document, user: user, account: account).call
    end

    def initialize(item:, document:, user:, account:)
      @item = item
      @document = document
      @user = user
      @account = account || item.onboarding_checklist.account
    end

    def call
      return @item if @item.complete?

      @item.mark_received!(document: @document, user: @user)

      if @user && @document.nil?
        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "onboarding_item.marked_manual",
          subject: @item,
          metadata: { client_id: @item.onboarding_checklist.client_id, item_name: @item.name }
        )
      end

      checklist = @item.onboarding_checklist
      if checklist.all_items_complete?
        Clients::ActivateFromOnboarding.call(
          client: checklist.client,
          user: @user,
          automatic: true
        )
      end

      @item
    end
  end
end

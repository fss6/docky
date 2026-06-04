# frozen_string_literal: true

module Collection
  class FlushScheduledDispatches
    def self.call
      new.call
    end

    def call
      enqueued = 0

      CollectionDispatch.status_scheduled
        .includes(:account, :client, :collection_step, period: :items)
        .find_each do |dispatch|
          enqueued += 1 if process_dispatch(dispatch)
        end

      enqueued
    end

    private

    def process_dispatch(dispatch)
      ActsAsTenant.with_tenant(dispatch.account) do
        settings = CollectionSetting.ensure_for!(dispatch.account)
        return false unless settings.enabled?

        return false if QuietHours.outside?(settings: settings)

        step = dispatch.collection_step
        client = dispatch.client
        period_record = dispatch.period
        pending_items = period_record.items.select(&:awaiting_receipt?)
        return false if pending_items.empty?

        reason = ChannelEligibility.skip_reason(
          channel: dispatch.channel,
          client: client,
          account: dispatch.account,
          step: step,
          settings: settings
        )
        if reason
          dispatch.mark_skipped!(reason: reason)
          return false
        end

        PopulateDispatchContent.call(dispatch: dispatch, step: step, pending_items: pending_items)
        Collection::SendDispatchJob.perform_later(dispatch.id)
        true
      end
    end
  end
end

# frozen_string_literal: true

module Collection
  class EvaluateClientPeriod
    def self.call(client:, period_record:, settings:, reference_date: Date.current)
      new(
        client: client,
        period_record: period_record,
        settings: settings,
        reference_date: reference_date
      ).call
    end

    def initialize(client:, period_record:, settings:, reference_date: Date.current)
      @client = client
      @period_record = period_record
      @settings = settings
      @reference_date = reference_date.to_date
      @account = period_record.account
      @period = period_record.period
    end

    def call
      return [] unless @settings.enabled?
      return [] if @client.archived? || @client.onboarding?
      return [] if @period_record.closed?

      pending_items = @period_record.items.select(&:awaiting_receipt?)
      return [] if pending_items.empty?

      days_offset = @reference_date - Deadline.for(client: @client, period: @period)
      step = @account.collection_steps.find_by(offset_days: days_offset)
      return [] unless step

      channels = channels_for(step)
      return [] if channels.empty?
      return [] unless ChannelEligibility.any_deliverable?(
        channels: channels,
        client: @client,
        account: @account,
        step: step,
        settings: @settings
      )

      dispatches = []
      channels.each do |channel|
        dispatches << schedule_or_skip(channel: channel, step: step, pending_items: pending_items)
      end
      dispatches.compact
    end

    private

    def channels_for(step)
      if step.kind_internal_alert?
        step.email_enabled? ? [:internal] : []
      else
        list = []
        list << :email if step.email_enabled?
        list << :whatsapp if step.whatsapp_enabled?
        list
      end
    end

    def schedule_or_skip(channel:, step:, pending_items:)
      existing = CollectionDispatch.find_by(
        client: @client,
        period: @period_record,
        collection_step: step,
        channel: channel
      )
      return finalize_dispatch(existing, channel: channel, step: step, pending_items: pending_items) if existing

      dispatch = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period_record,
        collection_step: step,
        channel: channel,
        status: :scheduled
      )

      finalize_dispatch(dispatch, channel: channel, step: step, pending_items: pending_items)
    rescue ActiveRecord::RecordNotUnique
      existing = CollectionDispatch.find_by!(
        client: @client,
        period: @period_record,
        collection_step: step,
        channel: channel
      )
      finalize_dispatch(existing, channel: channel, step: step, pending_items: pending_items)
    end

    def finalize_dispatch(dispatch, channel:, step:, pending_items:)
      return dispatch unless dispatch.status_scheduled?

      reason = ChannelEligibility.skip_reason(
        channel: channel,
        client: @client,
        account: @account,
        step: step,
        settings: @settings
      )
      if reason
        dispatch.mark_skipped!(reason: reason)
        return dispatch
      end

      return dispatch if QuietHours.outside?(settings: @settings)

      enqueue_send!(dispatch, step: step, pending_items: pending_items)
      dispatch
    end

    def enqueue_send!(dispatch, step:, pending_items:)
      PopulateDispatchContent.call(dispatch: dispatch, step: step, pending_items: pending_items)
      Collection::SendDispatchJob.perform_later(dispatch.id)
    end
  end
end

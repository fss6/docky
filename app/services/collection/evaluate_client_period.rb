# frozen_string_literal: true

module Collection
  class EvaluateClientPeriod
    def self.call(client:, period_record:, settings:)
      new(client: client, period_record: period_record, settings: settings).call
    end

    def initialize(client:, period_record:, settings:)
      @client = client
      @period_record = period_record
      @settings = settings
      @account = period_record.account
      @period = period_record.period
    end

    def call
      return [] unless @settings.enabled?
      return [] if @client.archived? || @client.onboarding?
      return [] if @period_record.closed?

      pending_items = @period_record.items.select(&:awaiting_receipt?)
      return [] if pending_items.empty?

      days_offset = Date.current - Deadline.for(client: @client, period: @period)
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
      return existing if existing

      dispatch = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period_record,
        collection_step: step,
        channel: channel,
        status: :scheduled
      )

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

      if QuietHours.outside?(settings: @settings)
        return dispatch
      end

      populate_rendered_content!(dispatch, step: step, pending_items: pending_items)
      Collection::SendDispatchJob.perform_later(dispatch.id)
      dispatch
    rescue ActiveRecord::RecordNotUnique
      CollectionDispatch.find_by!(
        client: @client,
        period: @period_record,
        collection_step: step,
        channel: channel
      )
    end

    def populate_rendered_content!(dispatch, step:, pending_items:)
      invite = EnsureUploadInvite.call(client: @client, period: @period, account: @account)
      url = Clients::PublicUploadUrl.for(token: invite.token)
      renderer = MessageRenderer.new(
        client: @client,
        period: @period,
        period_record: @period_record,
        pending_items: pending_items,
        upload_url: url,
        account: @account
      )

      case dispatch.channel.to_sym
      when :email, :internal
        dispatch.update!(
          rendered_subject: renderer.render_template(step.email_subject_template, step: step),
          rendered_body: renderer.render_template(step.email_body_template, step: step)
        )
      when :whatsapp
        dispatch.update!(
          rendered_body: renderer.render_template(step.whatsapp_body_template, step: step)
        )
      end
    end
  end
end

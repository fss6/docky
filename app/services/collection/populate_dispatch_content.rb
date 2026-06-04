# frozen_string_literal: true

module Collection
  class PopulateDispatchContent
    def self.call(dispatch:, step:, pending_items:)
      new(dispatch: dispatch, step: step, pending_items: pending_items).call
    end

    def initialize(dispatch:, step:, pending_items:)
      @dispatch = dispatch
      @step = step
      @pending_items = pending_items
      @client = dispatch.client
      @account = dispatch.account
      @period_record = dispatch.period
      @period = @period_record.period
    end

    def call
      return if content_present?

      invite = EnsureUploadInvite.call(client: @client, period: @period, account: @account)
      url = Clients::PublicUploadUrl.for(token: invite.token)
      renderer = MessageRenderer.new(
        client: @client,
        period: @period,
        period_record: @period_record,
        pending_items: @pending_items,
        upload_url: url,
        account: @account
      )

      case @dispatch.channel.to_sym
      when :email, :internal
        @dispatch.update!(
          rendered_subject: renderer.render_template(@step.email_subject_template, step: @step),
          rendered_body: renderer.render_template(@step.email_body_template, step: @step)
        )
      when :whatsapp
        @dispatch.update!(
          rendered_body: renderer.render_template(@step.whatsapp_body_template, step: @step)
        )
      end
    end

    private

    def content_present?
      case @dispatch.channel.to_sym
      when :email, :internal
        @dispatch.rendered_subject.present? && @dispatch.rendered_body.present?
      when :whatsapp
        @dispatch.rendered_body.present?
      else
        true
      end
    end
  end
end

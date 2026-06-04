# frozen_string_literal: true

module Collection
  class SendDispatch
    def self.call(dispatch)
      new(dispatch).call
    end

    def initialize(dispatch)
      @dispatch = dispatch
      @client = dispatch.client
      @account = dispatch.account
      @step = dispatch.collection_step
    end

    def call
      return @dispatch unless @dispatch.status_scheduled?

      @client.with_lock do
        @dispatch.reload
        return @dispatch unless @dispatch.status_scheduled?

        settings = CollectionSetting.ensure_for!(@account)
        reason = ChannelEligibility.skip_reason(
          channel: @dispatch.channel,
          client: @client,
          account: @account,
          step: @step,
          settings: settings
        )
        if reason
          @dispatch.mark_skipped!(reason: reason)
          return @dispatch
        end

        PlatformSettings::Delivery.apply!

        case @dispatch.channel.to_sym
        when :email
          send_client_email!
        when :whatsapp
          send_whatsapp!
        when :internal
          send_internal_email!
        end
      end
    rescue StandardError => e
      @dispatch.mark_failed!(reason: e.message.to_s.truncate(500))
      raise
    end

    private

    def send_client_email!
      invite = EnsureUploadInvite.call(client: @client, period: @dispatch.period.period, account: @account)
      url = Clients::PublicUploadUrl.for(token: invite.token)
      token = UnsubscribeToken.generate(@client)

      CollectionReminderMailer.client_reminder(
        dispatch: @dispatch,
        client: @client,
        upload_url: url,
        unsubscribe_token: token
      ).deliver_now

      @dispatch.mark_sent!
      record_audit!("collection.email_sent")
    end

    def send_internal_email!
      CollectionReminderMailer.internal_alert(
        dispatch: @dispatch,
        recipient: @account.contact_email
      ).deliver_now

      @dispatch.mark_sent!
      record_audit!("collection.internal_alert_sent")
    end

    def send_whatsapp!
      response = Whatsapp::ChannelResolver.client.send_template_message(
        to: @client.phone,
        template_name: @step.whatsapp_template_name,
        components: whatsapp_components
      )
      wamid = response.dig("messages", 0, "id")
      @dispatch.mark_sent!(provider_message_id: wamid)
      record_audit!("collection.whatsapp_sent")
    end

    def whatsapp_components
      [
        {
          type: "body",
          parameters: [
            { type: "text", text: @client.name.to_s.truncate(80) },
            { type: "text", text: body_documents_summary.truncate(900) },
            { type: "text", text: prazo_text.truncate(40) }
          ]
        },
        {
          type: "button",
          sub_type: "url",
          index: "0",
          parameters: [
            { type: "text", text: upload_path_for_template }
          ]
        }
      ]
    end

    def body_documents_summary
      @dispatch.rendered_body.to_s.lines.map(&:strip).reject(&:blank?).first(5).join(" ")
    end

    def prazo_text
      Deadline.for(client: @client, period: @dispatch.period.period).then { |d| I18n.l(d, format: :short) }
    end

    def upload_path_for_template
      invite = EnsureUploadInvite.call(client: @client, period: @dispatch.period.period, account: @account)
      uri = URI(Clients::PublicUploadUrl.for(token: invite.token))
      uri.path.delete_prefix("/")
    end

    def record_audit!(event_type)
      AuditEvents::Recorder.call(
        account: @account,
        user: nil,
        event_type: event_type,
        subject: @dispatch,
        metadata: {
          client_id: @client.id,
          period: @dispatch.period.period.strftime("%Y-%m"),
          channel: @dispatch.channel,
          step_name: @step.name
        }
      )
    end
  end
end

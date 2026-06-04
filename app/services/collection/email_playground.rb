# frozen_string_literal: true

require "ostruct"

module Collection
  class EmailPlayground
    Preview = Struct.new(:subject, :body, :html, keyword_init: true)
    Result = Struct.new(:success, :error, keyword_init: true)

    FALLBACK_PENDING_ITEMS = [
      OpenStruct.new(name_snapshot: "Nota fiscal"),
      OpenStruct.new(name_snapshot: "Extrato bancário")
    ].freeze

    def self.preview(**kwargs)
      new(**kwargs).preview
    end

    def self.send_test!(**kwargs)
      new(**kwargs).send_test!
    end

    def initialize(step:, client:, account:, subject_template:, body_template:, recipient:)
      @step = step
      @client = client
      @account = account
      @subject_template = subject_template
      @body_template = body_template
      @recipient = recipient.to_s.strip
    end

    def preview
      ensure_smtp_configured!

      mail = build_mail
      Preview.new(
        subject: mail.subject,
        body: dispatch.rendered_body,
        html: html_preview_fragment(html_body_for(mail))
      )
    end

    def send_test!
      ensure_smtp_configured!
      return failure("Informe um e-mail de destino.") if @recipient.blank?

      PlatformSettings::Delivery.apply!
      build_mail.deliver_now
      Result.new(success: true)
    rescue StandardError => e
      failure(e.message.to_s.truncate(500))
    end

    private

    def ensure_smtp_configured!
      return if ActionMailerDelivery.enabled?

      raise StandardError, "Configure o SMTP antes de testar o e-mail."
    end

    def build_mail
      if @step.kind_internal_alert?
        CollectionReminderMailer.internal_alert(
          dispatch: dispatch,
          recipient: @account.contact_email.presence || @recipient,
          to: @recipient
        )
      else
        CollectionReminderMailer.client_reminder(
          dispatch: dispatch,
          client: @client,
          upload_url: upload_url,
          unsubscribe_token: UnsubscribeToken.generate(@client),
          to: @recipient,
          test_mode: true
        )
      end
    end

    def dispatch
      @dispatch ||= TestDispatch.new(
        rendered_subject: renderer.render_template(@subject_template, step: @step),
        rendered_body: renderer.render_template(@body_template, step: @step),
        client: @client
      )
    end

    def renderer
      @renderer ||= MessageRenderer.new(
        client: @client,
        period: period,
        period_record: period_record,
        pending_items: pending_items,
        upload_url: upload_url,
        account: @account
      )
    end

    def period_record
      @period_record ||= @client.periods.with_pending_receipts.first ||
        @client.periods.open_periods.order(period: :desc).first
    end

    def period
      @period ||= period_record&.period || Date.current.beginning_of_month
    end

    def pending_items
      items = period_record&.items&.select(&:awaiting_receipt?) || []
      items.presence || FALLBACK_PENDING_ITEMS
    end

    def upload_url
      @upload_url ||= begin
        invite = EnsureUploadInvite.call(client: @client, period: period, account: @account)
        Clients::PublicUploadUrl.for(token: invite.token)
      end
    end

    def html_body_for(mail)
      part = mail.html_part || mail
      part.body.decoded
    end

    def html_preview_fragment(html)
      doc = Nokogiri::HTML(html)
      body = doc.at_css("body")
      return html unless body

      style = body["style"]
      wrapper_open = if style.present?
        %(<div style="#{ERB::Util.html_escape(style)}">)
      else
        "<div>"
      end
      "#{wrapper_open}#{body.inner_html}</div>"
    end

    def failure(message)
      Result.new(success: false, error: message)
    end
  end
end

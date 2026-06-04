# frozen_string_literal: true

require "ostruct"

module PlatformSettings
  class SendTestEmail
    Result = Struct.new(:success, :error, keyword_init: true)

    def self.call(recipient:)
      new(recipient: recipient).call
    end

    def initialize(recipient:)
      @recipient = recipient.to_s.strip
    end

    def call
      return failure("Informe um e-mail de destino.") if @recipient.blank?
      return failure("Configure o SMTP antes de enviar o teste.") unless SmtpConfig.configured?

      templates = Collection::SampleContext.default_step_templates
      context = Collection::SampleContext.new
      sample_client = OpenStruct.new(name: context.replacements.fetch("cliente"), email: @recipient)

      dispatch = Collection::TestDispatch.new(
        rendered_subject: context.render_template(templates[:email_subject_template]),
        rendered_body: context.render_template(templates[:email_body_template]),
        client: sample_client
      )

      Delivery.apply!

      CollectionReminderMailer.client_reminder(
        dispatch: dispatch,
        client: sample_client,
        upload_url: Collection::SampleContext::SAMPLE_UPLOAD_URL,
        unsubscribe_token: "test",
        to: @recipient,
        test_mode: true
      ).deliver_now

      Result.new(success: true)
    rescue StandardError => e
      failure(e.message.to_s.truncate(500))
    end

    private

    def failure(message)
      Result.new(success: false, error: message)
    end
  end
end

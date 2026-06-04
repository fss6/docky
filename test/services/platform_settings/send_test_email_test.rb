# frozen_string_literal: true

require "test_helper"

module PlatformSettings
  class SendTestEmailTest < ActiveSupport::TestCase
    setup do
      PlatformSetting.reset_cache!
    end

    test "sends test email with sample templates when smtp configured" do
      assert PlatformSettings::SmtpConfig.configured?

      assert_emails 1 do
        result = SendTestEmail.call(recipient: "admin@example.com")
        assert result.success, result.error
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal [ "admin@example.com" ], mail.to
      assert_includes mail.subject, "[TESTE]"
      assert_includes mail.subject, "Documentos pendentes para fechamento contábil"
      assert_includes mail.text_part.body.decoded, "Cliente Exemplo Ltda."
    end

    test "returns failure when smtp not configured" do
      PlatformSettings::SmtpConfig.stub(:configured?, false) do
        result = SendTestEmail.call(recipient: "admin@example.com")
        assert_not result.success
        assert_includes result.error, "SMTP"
      end
    end

    test "returns failure when recipient blank" do
      result = SendTestEmail.call(recipient: "")
      assert_not result.success
      assert_includes result.error, "e-mail"
    end
  end
end

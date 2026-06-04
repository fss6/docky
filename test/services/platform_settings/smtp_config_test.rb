# frozen_string_literal: true

require "test_helper"

module PlatformSettings
  class SmtpConfigTest < ActiveSupport::TestCase
    setup do
      PlatformSetting.reset_cache!
    end

    test "configured from database when smtp complete" do
      assert SmtpConfig.configured?
      assert SmtpConfig.from_database?
      assert_equal "smtp", SmtpConfig.mode
    end

    test "falls back to env when database empty" do
      platform_settings(:default).update!(
        mail_delivery: nil,
        smtp_username: nil,
        smtp_password: nil
      )
      PlatformSetting.reset_cache!

      with_env("MAIL_DELIVERY" => "gmail", "SMTP_USERNAME" => "u", "SMTP_PASSWORD" => "p") do
        assert SmtpConfig.configured?
        assert_not SmtpConfig.from_database?
        assert_equal "gmail", SmtpConfig.mode
      end
    end

    test "falls back when platform_settings table is not ready" do
      PlatformSetting.stub(:table_ready?, false) do
        PlatformSetting.reset_cache!

        with_env("MAIL_DELIVERY" => "gmail", "SMTP_USERNAME" => "u", "SMTP_PASSWORD" => "p") do
          assert SmtpConfig.configured?
          assert_not SmtpConfig.from_database?
          assert_equal "gmail", SmtpConfig.mode
        end
      end
    end

    test "apply_runtime does not recurse when using env fallback" do
      platform_settings(:default).update!(
        mail_delivery: nil,
        smtp_username: nil,
        smtp_password: nil
      )
      PlatformSetting.reset_cache!

      mailer = Class.new do
        attr_accessor :delivery_method, :perform_deliveries, :raise_delivery_errors, :smtp_settings, :default_options
      end.new

      with_env("MAIL_DELIVERY" => "gmail", "SMTP_USERNAME" => "u", "SMTP_PASSWORD" => "p") do
        assert SmtpConfig.apply_runtime!(mailer)
        assert_equal :smtp, mailer.delivery_method
        assert_equal "smtp.gmail.com", mailer.smtp_settings[:address]
      end
    end
  end
end

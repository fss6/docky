# frozen_string_literal: true

require "test_helper"

module Whatsapp
  class PlatformConfigTest < ActiveSupport::TestCase
    setup do
      PlatformSetting.reset_cache!
      @env_backup = %w[
        WHATSAPP_ACCESS_TOKEN
        WHATSAPP_PHONE_NUMBER_ID
        WHATSAPP_APP_SECRET
        WHATSAPP_VERIFY_TOKEN
      ].index_with { |k| ENV[k] }
    end

    teardown do
      @env_backup&.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      PlatformSetting.reset_cache!
      if PlatformSettings::WhatsappConfig.instance_variable_defined?(:@credentials_hash)
        PlatformSettings::WhatsappConfig.remove_instance_variable(:@credentials_hash)
      end
    end

    test "configured? when required env vars present" do
      ENV["WHATSAPP_ACCESS_TOKEN"] = "token"
      ENV["WHATSAPP_PHONE_NUMBER_ID"] = "123"
      ENV["WHATSAPP_APP_SECRET"] = "secret"
      ENV["WHATSAPP_VERIFY_TOKEN"] = "verify"

      assert PlatformConfig.configured?
      assert_empty PlatformConfig.missing_keys
    end

    test "not configured when missing token" do
      platform_settings(:default).update!(whatsapp_access_token: nil)
      PlatformSetting.reset_cache!

      ENV.delete("WHATSAPP_ACCESS_TOKEN")
      ENV["WHATSAPP_PHONE_NUMBER_ID"] = "123"
      ENV["WHATSAPP_APP_SECRET"] = "secret"
      ENV["WHATSAPP_VERIFY_TOKEN"] = "verify"

      assert_not PlatformConfig.configured?
      assert_includes PlatformConfig.missing_keys, :access_token
    end
  end
end

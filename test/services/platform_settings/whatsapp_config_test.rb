# frozen_string_literal: true

require "test_helper"

module PlatformSettings
  class WhatsappConfigTest < ActiveSupport::TestCase
    setup do
      PlatformSetting.reset_cache!
    end

    test "configured from database fixture" do
      assert WhatsappConfig.configured?
      assert WhatsappConfig.from_database?
      assert_equal "test-access-token", WhatsappConfig.access_token
    end

    test "missing keys when incomplete" do
      platform_settings(:default).update!(
        whatsapp_access_token: nil,
        whatsapp_phone_number_id: nil,
        whatsapp_app_secret: nil
      )
      PlatformSetting.reset_cache!

      assert_not WhatsappConfig.configured?
      assert_includes WhatsappConfig.missing_keys, :access_token
    end
  end
end

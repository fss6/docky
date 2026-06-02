# frozen_string_literal: true

require "test_helper"

class PlatformSettingTest < ActiveSupport::TestCase
  setup do
    PlatformSetting.reset_cache!
  end

  test "current reads through cache" do
    record = platform_settings(:default)
    Rails.cache.write(PlatformSetting::CACHE_KEY, record, expires_in: 1.minute)
    assert_equal record.singleton_key, PlatformSetting.current.singleton_key
  end

  test "invalidate cache on commit" do
    setting = platform_settings(:default)
    Rails.cache.write(PlatformSetting::CACHE_KEY, setting)
    setting.update!(mailer_from: "updated@example.com")
    assert_nil Rails.cache.read(PlatformSetting::CACHE_KEY)
  end

  test "generates whatsapp verify token when blank" do
    setting = PlatformSetting.new(singleton_key: "default")
    setting.valid?
    assert setting.whatsapp_verify_token.present?
  end

  test "encrypts smtp password round trip" do
    setting = platform_settings(:default)
    setting.update!(smtp_password: "new-secret")
    setting.reload
    assert_equal "new-secret", setting.smtp_password
  end
end

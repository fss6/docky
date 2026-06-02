# frozen_string_literal: true

require "test_helper"

class PlatformSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    PlatformSetting.reset_cache!
    @setting = platform_settings(:default)
  end

  test "administrator can view platform settings" do
    sign_in users(:administrator)
    get platform_settings_path
    assert_response :success
    assert_select "h1", text: /Configurações da plataforma/
  end

  test "owner cannot access platform settings" do
    sign_in users(:owner)
    get platform_settings_path
    assert_redirected_to authenticated_root_path
  end

  test "administrator updates smtp and preserves blank password" do
    sign_in users(:administrator)
    original_password = @setting.smtp_password

    patch platform_settings_path, params: {
      platform_setting: {
        mail_delivery: "smtp",
        smtp_address: "smtp.new.example.com",
        smtp_port: 587,
        smtp_domain: "new.example.com",
        smtp_username: "mailer@new.example.com",
        smtp_password: "",
        smtp_authentication: "plain",
        mailer_from: "noreply@new.example.com"
      }
    }

    assert_redirected_to platform_settings_path
    @setting.reload
    assert_equal "smtp.new.example.com", @setting.smtp_address
    assert_equal original_password, @setting.smtp_password
  end

  test "administrator regenerates whatsapp verify token" do
    sign_in users(:administrator)
    old_token = @setting.whatsapp_verify_token

    post regenerate_whatsapp_verify_token_platform_settings_path

    assert_redirected_to platform_settings_path
    assert_not_equal old_token, @setting.reload.whatsapp_verify_token
  end
end

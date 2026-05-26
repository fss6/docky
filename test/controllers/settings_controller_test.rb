# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
    ActsAsTenant.with_tenant(accounts(:one)) do
      @setting = accounts(:one).setting || accounts(:one).create_setting!
    end
  end

  test "update persists upload share templates" do
    patch settings_path, params: {
      setting: {
        upload_share_whatsapp_template: "WhatsApp {{nome_cliente}} {{link}}",
        upload_share_email_subject_template: "Assunto {{nome_cliente}}",
        upload_share_email_body_template: "Corpo {{link}} {{competencia}}"
      }
    }

    assert_redirected_to settings_path
  end

  test "update rejects templates without link in whatsapp and body" do
    patch settings_path, params: {
      setting: {
        upload_share_whatsapp_template: "Sem placeholder",
        upload_share_email_subject_template: "Assunto ok",
        upload_share_email_body_template: "Corpo sem link"
      }
    }

    assert_response :unprocessable_entity
    @setting.reload
    assert_not_equal "Sem placeholder", @setting.upload_share_whatsapp_template
  end
end

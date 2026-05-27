# frozen_string_literal: true

require "test_helper"

class Settings::UploadSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
    ActsAsTenant.with_tenant(accounts(:one)) do
      @setting = accounts(:one).setting || accounts(:one).create_setting!
    end
  end

  test "edit renders" do
    get edit_settings_upload_share_path

    assert_response :success
    assert_select "h1", text: "Compartilhamento mensal"
  end

  test "update persists upload share templates" do
    patch settings_upload_share_path, params: {
      setting: {
        upload_share_whatsapp_template: "WhatsApp {{nome_cliente}} {{link}}",
        upload_share_email_subject_template: "Assunto {{nome_cliente}}",
        upload_share_email_body_template: "Corpo {{link}} {{competencia}}"
      }
    }

    assert_redirected_to edit_settings_upload_share_path
  end

  test "update rejects templates without required link placeholder" do
    patch settings_upload_share_path, params: {
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

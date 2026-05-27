# frozen_string_literal: true

require "test_helper"

class Settings::OnboardingSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
    ActsAsTenant.with_tenant(accounts(:one)) do
      @setting = accounts(:one).setting || accounts(:one).create_setting!
    end
  end

  test "edit renders" do
    get edit_settings_onboarding_share_path

    assert_response :success
    assert_select "h1", text: "Mensagens de onboarding"
  end

  test "update persists onboarding share templates" do
    patch settings_onboarding_share_path, params: {
      setting: {
        onboarding_share_whatsapp_template: "Onboarding {{nome_cliente}} {{link}}",
        onboarding_share_email_subject_template: "Assunto onboarding {{nome_cliente}}",
        onboarding_share_email_body_template: "Corpo onboarding {{link}} {{progresso}}"
      }
    }

    assert_redirected_to edit_settings_onboarding_share_path
  end

  test "update rejects onboarding templates without required link placeholder" do
    patch settings_onboarding_share_path, params: {
      setting: {
        onboarding_share_whatsapp_template: "Sem placeholder",
        onboarding_share_email_subject_template: "Assunto onboarding",
        onboarding_share_email_body_template: "Corpo onboarding sem link"
      }
    }

    assert_response :unprocessable_entity
    @setting.reload
    assert_not_equal "Sem placeholder", @setting.onboarding_share_whatsapp_template
  end
end

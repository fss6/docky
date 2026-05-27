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

  test "show renders settings hub cards and links" do
    get settings_path

    assert_response :success
    assert_select "h2", text: "Templates de itens"
    assert_select "a[href=?]", settings_onboarding_templates_path
    assert_select "a[href=?]", edit_settings_ai_settings_path
    assert_select "a[href=?]", edit_settings_upload_share_path
    assert_select "a[href=?]", edit_settings_onboarding_share_path
  end
end

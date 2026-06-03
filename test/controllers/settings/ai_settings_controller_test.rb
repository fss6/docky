# frozen_string_literal: true

require "test_helper"

class Settings::AiSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
    ActsAsTenant.with_tenant(accounts(:one)) do
      @setting = accounts(:one).setting || accounts(:one).create_setting!
    end
  end

  test "edit renders" do
    get edit_settings_ai_settings_path

    assert_response :success
    assert_select "h1", text: "Automações com IA"
  end

  test "update persists ai toggle" do
    patch settings_ai_settings_path, params: { setting: { generate_tags_automatically: false } }

    assert_redirected_to edit_settings_ai_settings_path
    assert_equal false, @setting.reload.generate_tags_automatically
  end
end

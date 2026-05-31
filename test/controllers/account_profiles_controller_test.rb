# frozen_string_literal: true

require "test_helper"

class AccountProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @member = users(:three)
    @account = accounts(:one)
  end

  test "owner can get edit account profile" do
    sign_in @owner

    get edit_account_profile_path

    assert_response :success
    assert_select "h1", text: I18n.t("account_profiles.edit.title")
  end

  test "owner can update name description and contact email" do
    sign_in @owner

    patch account_profile_path, params: {
      account: {
        name: "Escritório Atualizado",
        description: "Nova descrição",
        contact_email: "contato@escritorio.com"
      }
    }

    assert_redirected_to edit_account_profile_path
    @account.reload
    assert_equal "Escritório Atualizado", @account.name
    assert_equal "Nova descrição", @account.description
    assert_equal "contato@escritorio.com", @account.contact_email
  end

  test "owner can upload logo" do
    sign_in @owner
    file = fixture_file_upload("avatar.png", "image/png")

    patch account_profile_path, params: { account: { logo: file } }

    assert_redirected_to edit_account_profile_path
    assert @account.reload.logo.attached?
  end

  test "owner cannot upload invalid logo" do
    sign_in @owner
    file = fixture_file_upload("minimal.pdf", "application/pdf")

    patch account_profile_path, params: { account: { logo: file } }

    assert_response :unprocessable_entity
    assert_not @account.reload.logo.attached?
  end

  test "owner can remove logo" do
    sign_in @owner
    @account.logo.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "logo.png",
      content_type: "image/png"
    )

    patch account_profile_path, params: { account: { remove_logo: "1" } }

    assert_redirected_to edit_account_profile_path
    assert_not @account.reload.logo.attached?
  end

  test "member cannot access account profile edit" do
    sign_out :user
    sign_in @member

    get edit_account_profile_path

    assert_redirected_to authenticated_root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "owner still cannot access accounts index" do
    sign_in @owner

    get accounts_url

    assert_redirected_to authenticated_root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "owner menu shows office profile link" do
    sign_in @owner

    get dashboard_path

    assert_response :success
    assert_select "a[href=?]", edit_account_profile_path, text: I18n.t("account_profiles.menu.edit")
  end

  test "member menu does not show office profile link" do
    sign_out :user
    sign_in @member

    get dashboard_path

    assert_response :success
    assert_select "a[href=?]", edit_account_profile_path, count: 0
  end

  test "unauthenticated user is redirected to login" do
    sign_out :user

    get edit_account_profile_path

    assert_redirected_to new_user_session_path
  end
end

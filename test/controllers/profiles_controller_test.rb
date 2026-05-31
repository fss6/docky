# frozen_string_literal: true

require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:three)
  end

  test "member can get edit profile" do
    sign_in @member

    get edit_profile_path

    assert_response :success
    assert_select "h1", text: I18n.t("profiles.edit.title")
  end

  test "member can update name and email" do
    sign_in @member

    patch profile_path, params: {
      user: { name: "Nome Atualizado", email: "atualizado@example.com" }
    }

    assert_redirected_to edit_profile_path
    assert_equal "Nome Atualizado", @member.reload.name
    assert_equal "atualizado@example.com", @member.email
  end

  test "member can upload avatar" do
    sign_in @member
    file = fixture_file_upload("avatar.png", "image/png")

    patch profile_path, params: { user: { avatar: file } }

    assert_redirected_to edit_profile_path
    assert @member.reload.avatar.attached?
  end

  test "member cannot upload invalid avatar" do
    sign_in @member
    file = fixture_file_upload("minimal.pdf", "application/pdf")

    patch profile_path, params: { user: { avatar: file } }

    assert_response :unprocessable_entity
    assert_not @member.reload.avatar.attached?
  end

  test "member can remove avatar" do
    sign_in @member
    @member.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    patch profile_path, params: { user: { remove_avatar: "1" } }

    assert_redirected_to edit_profile_path
    assert_not @member.reload.avatar.attached?
  end

  test "unauthenticated user is redirected to login" do
    sign_out :user

    get edit_profile_path

    assert_redirected_to new_user_session_path
  end

  test "member still cannot access users index" do
    sign_in @member

    get users_url

    assert_redirected_to authenticated_root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "top bar shows edit profile link for member" do
    sign_in @member

    get dashboard_path

    assert_response :success
    assert_select "a[href=?]", edit_profile_path, text: I18n.t("profiles.menu.edit")
  end
end

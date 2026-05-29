# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @user = users(:one)
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_emails 1 do
      assert_difference("User.count") do
        post users_url, params: { user: { active: true, email: "novo_convite@example.com", name: "Novo", role: "member" } }
      end
    end

    assert_redirected_to user_url(User.last)
    assert_match(/e-mail|senha/i, flash[:notice].to_s)
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: { user: { active: @user.active, email: @user.email, name: @user.name, role: @user.role } }
    assert_redirected_to user_url(@user)
  end

  test "cannot demote founding user even with another active owner" do
    owner = users(:owner)
    assert owner.founding_user?

    User.create!(
      account: owner.account,
      name: "Co-owner",
      email: "co-owner-#{SecureRandom.hex(4)}@example.com",
      role: :owner,
      active: true,
      founding_user: false,
      password: "password123",
      password_confirmation: "password123"
    )

    patch user_url(owner), params: {
      user: { name: owner.name, email: owner.email, active: true, role: "member" }
    }

    assert_response :unprocessable_entity
    assert owner.reload.role_owner?
  end

  test "can demote non-founding co-owner when founding owner remains active" do
    founding = users(:owner)
    co_owner = User.create!(
      account: founding.account,
      name: "Co-owner",
      email: "co-owner-#{SecureRandom.hex(4)}@example.com",
      role: :owner,
      active: true,
      founding_user: false,
      password: "password123",
      password_confirmation: "password123"
    )

    patch user_url(co_owner), params: {
      user: { name: co_owner.name, email: co_owner.email, active: true, role: "member" }
    }

    assert_redirected_to user_url(co_owner)
    assert founding.reload.role_owner?
    assert co_owner.reload.role_member?
  end

  test "owner cannot demote self via update" do
    owner = users(:owner)

    patch user_url(owner), params: {
      user: { name: owner.name, email: owner.email, active: true, role: "member" }
    }

    assert_response :unprocessable_entity
    assert owner.reload.role_owner?
  end

  test "cannot disable own user" do
    assert_no_changes -> { users(:owner).reload.active? } do
      delete user_url(users(:owner))
    end
    assert_redirected_to authenticated_root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "cannot disable founding user as administrator" do
    sign_in users(:administrator)

    assert_no_changes -> { users(:owner).reload.active? } do
      delete user_url(users(:owner))
    end
    assert_redirected_to authenticated_root_path
  end

  test "can disable co-owner when founding owner remains active" do
    founding = users(:owner)
    co_owner = User.create!(
      account: founding.account,
      name: "Co-owner",
      email: "co-owner-#{SecureRandom.hex(4)}@example.com",
      role: :owner,
      active: true,
      founding_user: false,
      password: "password123",
      password_confirmation: "password123"
    )

    delete user_url(co_owner)

    assert_response :redirect
    assert_not co_owner.reload.active?
    assert founding.reload.active?
    assert founding.role_owner?
  end

  test "member cannot access users index" do
    sign_out :user
    sign_in users(:three)

    get users_url
    assert_redirected_to authenticated_root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "should disable user from index returns to index" do
    active = users(:three)
    assert active.active?

    assert_no_difference("User.count") do
      delete user_url(active), headers: { "Referer" => users_url }
    end

    assert_redirected_to users_url
    assert_equal false, active.reload.active
  end

  test "should disable user from show returns to show" do
    active = users(:three)
    delete user_url(active), headers: { "Referer" => user_url(active) }

    assert_redirected_to user_url(active)
    assert_equal false, active.reload.active
  end

  test "should enable user without referer falls back to user show" do
    inactive = users(:one)
    assert_not inactive.active?

    post enable_user_url(inactive)

    assert_redirected_to user_url(inactive)
    assert inactive.reload.active?
  end

  test "should enable user from index returns to index" do
    inactive = users(:one)
    inactive.update_column(:active, false)

    post enable_user_url(inactive), headers: { "Referer" => users_url }

    assert_redirected_to users_url
    assert inactive.reload.active?
  end
end

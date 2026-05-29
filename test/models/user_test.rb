# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "inactive user is not active for authentication" do
    user = users(:one)

    assert_not user.active_for_authentication?
  end

  test "active user is active for authentication" do
    user = users(:three)

    assert user.active_for_authentication?
  end

  test "founding user cannot be demoted even with another active owner" do
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

    owner.role = :member

    assert_not owner.valid?
    assert_includes owner.errors[:role], I18n.t("activerecord.errors.models.user.attributes.role.founding_owner")
  end

  test "founding user cannot be deactivated" do
    owner = users(:owner)
    owner.active = false

    assert_not owner.valid?
    assert_includes owner.errors[:active], I18n.t("activerecord.errors.models.user.attributes.active.founding_owner")
  end

  test "non-founding owner can be demoted when another active owner exists" do
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

    co_owner.role = :member

    assert co_owner.valid?, co_owner.errors.full_messages.to_sentence
  end

  test "cannot demote owner when no other active owner would remain" do
    plan = plans(:one)
    account = Account.create!(name: "Conta sem fundador ativo", plan: plan, active: true)
    ActsAsTenant.without_tenant do
      sole = User.create!(
        account: account,
        name: "Único owner",
        email: "unico-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        founding_user: true,
        password: "password123",
        password_confirmation: "password123"
      )
      sole.update_column(:active, false)
      replacement = User.create!(
        account: account,
        name: "Substituto",
        email: "sub-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        founding_user: false,
        password: "password123",
        password_confirmation: "password123"
      )

      replacement.role = :member

      assert_not replacement.valid?
      assert_includes replacement.errors[:role], I18n.t("activerecord.errors.models.user.attributes.role.account_requires_active_owner")
    end
  end

  test "updater cannot change own role" do
    owner = users(:owner)
    owner.updated_by = owner
    owner.role = :member

    assert_not owner.valid?
    assert_includes owner.errors[:role], I18n.t("activerecord.errors.models.user.attributes.role.cannot_change_own_role")
  end

  test "first user on account is marked founding and must be owner" do
    plan = plans(:one)
    account = Account.create!(name: "Conta nova fundador", plan: plan, active: true)
    user = User.new(
      account: account,
      name: "Primeiro",
      email: "primeiro-#{SecureRandom.hex(4)}@example.com",
      role: :member,
      active: true,
      password: "password123",
      password_confirmation: "password123"
    )

    assert user.valid?
    assert user.founding_user?
    assert user.role_owner?
  end
end

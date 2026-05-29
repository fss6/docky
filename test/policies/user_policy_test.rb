# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  test "member without users.manage cannot index" do
    member = users(:three)
    grant = member.account.permission_grants.find_by!(capability_key: "users.manage")
    grant.update!(granted: false)
    Permissions.reset_cache!
    policy = UserPolicy.new(member, User)

    assert_not policy.index?
  end

  test "owner can manage users" do
    owner = users(:owner)
    policy = UserPolicy.new(owner, User)

    assert policy.index?
    assert policy.create?
  end

  test "cannot edit own role" do
    owner = users(:owner)
    policy = UserPolicy.new(owner, owner)

    assert_not policy.edit_role?
  end

  test "cannot edit founding user role" do
    owner = users(:owner)
    member = users(:three)

    assert_not UserPolicy.new(owner, owner).edit_role?
    assert UserPolicy.new(owner, member).edit_role?
  end

  test "cannot destroy founding user" do
    owner = users(:owner)
    policy = UserPolicy.new(owner, owner)

    assert_not policy.destroy?
  end

  test "can destroy co-owner when founding owner remains active" do
    owner = users(:owner)
    co_owner = User.create!(
      account: owner.account,
      name: "Co-owner",
      email: "co-owner-#{SecureRandom.hex(4)}@example.com",
      role: :owner,
      active: true,
      founding_user: false,
      password: "password123",
      password_confirmation: "password123"
    )
    policy = UserPolicy.new(owner, co_owner)

    assert policy.destroy?
  end

  test "cannot disable self" do
    owner = users(:owner)
    co_owner = User.create!(
      account: owner.account,
      name: "Co-owner",
      email: "co-owner-#{SecureRandom.hex(4)}@example.com",
      role: :owner,
      active: true,
      founding_user: false,
      password: "password123",
      password_confirmation: "password123"
    )
    policy = UserPolicy.new(co_owner, co_owner)

    assert_not policy.destroy?
  end
end

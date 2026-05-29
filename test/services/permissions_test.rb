# frozen_string_literal: true

require "test_helper"

class PermissionsTest < ActiveSupport::TestCase
  test "owner bypasses capability matrix" do
    owner = users(:owner)

    assert Permissions.allow?(owner, "users.manage")
    assert Permissions.allow?(owner, "audit.read")
  end

  test "member respects granted capability" do
    member = users(:three)
    grant = member.account.permission_grants.find_by!(capability_key: "users.manage")

    assert_not Permissions.allow?(member, "users.manage")

    grant.update!(granted: true)
    Permissions.reset_cache!

    assert Permissions.allow?(member, "users.manage")
  ensure
    grant.update!(granted: false)
    Permissions.reset_cache!
  end

  test "member falls back to catalog default when grant missing" do
    member = users(:three)
    member.account.permission_grants.delete_all
    Permissions.reset_cache!

    assert Permissions.allow?(member, "clients.read")
    assert_not Permissions.allow?(member, "users.manage")
  end

  test "inactive user is denied" do
    member = users(:one)
    member.update!(active: false)

    assert_not Permissions.allow?(member, "clients.read")
  end
end

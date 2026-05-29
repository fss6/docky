# frozen_string_literal: true

require "test_helper"

class AccountPermissionGrantTest < ActiveSupport::TestCase
  test "validates capability key against catalog" do
    grant = AccountPermissionGrant.new(
      account: accounts(:one),
      capability_key: "invalid.key",
      role: Permissions::Catalog::MEMBER_ROLE,
      granted: true
    )

    assert_not grant.valid?
    assert_includes grant.errors[:capability_key], "não está incluído na lista"
  end
end

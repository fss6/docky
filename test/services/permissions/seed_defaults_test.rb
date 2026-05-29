# frozen_string_literal: true

require "test_helper"

module Permissions
  class SeedDefaultsTest < ActiveSupport::TestCase
    test "creates all catalog grants for account" do
      account = accounts(:two)
      account.permission_grants.delete_all

      SeedDefaults.call(account: account)

      assert_equal Catalog.keys.size, account.permission_grants.count
      assert account.permission_grants.find_by!(capability_key: "clients.read").granted?
      assert_not account.permission_grants.find_by!(capability_key: "users.manage").granted?
    end

    test "is idempotent" do
      account = accounts(:two)
      account.permission_grants.delete_all
      SeedDefaults.call(account: account)
      before = account.permission_grants.order(:capability_key).pluck(:capability_key, :granted)

      SeedDefaults.call(account: account)

      assert_equal before, account.permission_grants.order(:capability_key).pluck(:capability_key, :granted)
    end
  end
end

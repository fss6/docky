# frozen_string_literal: true

module PermissionTestHelper
  def seed_account_permissions!
    Account.find_each do |account|
      Permissions::SeedDefaults.call(account: account) if account.permission_grants.none?
    end
  end
end

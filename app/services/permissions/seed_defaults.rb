# frozen_string_literal: true

module Permissions
  class SeedDefaults
    def self.call(account:)
      new(account: account).call
    end

    def initialize(account:)
      @account = account
    end

    def call
      Catalog.keys.each do |capability_key|
        grant = @account.permission_grants.find_or_initialize_by(
          capability_key: capability_key,
          role: Catalog::MEMBER_ROLE
        )
        grant.granted = Catalog.default_for_member(capability_key) if grant.new_record?
        grant.save! if grant.changed?
      end
    end
  end
end

# frozen_string_literal: true

module Permissions
  class << self
    def allow?(user, capability_key)
      return false unless user&.active?

      key = Catalog.normalize_key(capability_key)

      return true if user.role_owner?
      return Catalog.platform_capability?(key) if user.role_administrator?

      grant_for(user, key)
    end

    def reset_cache!
      Thread.current[:permissions_grants_by_account] = nil
    end

    private

    def grant_for(user, key)
      return Catalog.default_for_member(key) unless user.role_member?

      account = user.account
      return Catalog.default_for_member(key) unless account

      grants = grants_for_account(account)
      grant = grants[key]
      return grant.granted if grant

      Catalog.default_for_member(key)
    end

    def grants_for_account(account)
      cache = Thread.current[:permissions_grants_by_account] ||= {}
      cache[account.id] ||= account.permission_grants
        .where(role: Catalog::MEMBER_ROLE)
        .index_by(&:capability_key)
    end
  end
end

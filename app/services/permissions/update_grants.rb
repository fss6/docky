# frozen_string_literal: true

module Permissions
  class UpdateGrants
    def self.call(account:, grants_params:, changed_by:)
      new(account: account, grants_params: grants_params, changed_by: changed_by).call
    end

    def initialize(account:, grants_params:, changed_by:)
      @account = account
      @grants_params = grants_params
      @changed_by = changed_by
    end

    def call
      ActiveRecord::Base.transaction do
        Permissions::SeedDefaults.call(account: @account)

        keys_to_update = @grants_params.keys.presence || Catalog.keys
        keys_to_update.each do |capability_key|
          next unless Catalog.valid_key?(capability_key)

          granted = ActiveModel::Type::Boolean.new.cast(@grants_params[capability_key])
          grant = @account.permission_grants.find_by!(
            capability_key: capability_key,
            role: Catalog::MEMBER_ROLE
          )
          next if grant.granted == granted

          grant.update!(granted: granted)
          record_change(capability_key, granted)
        end
      end

      Permissions.reset_cache!
    end

    private

    def record_change(capability_key, granted)
      return unless @changed_by&.account

      AuditEvents::Recorder.call(
        account: @changed_by.account,
        user: @changed_by,
        event_type: "permission_grant.updated",
        subject: @account,
        metadata: {
          capability_key: capability_key,
          granted: granted,
          role: Catalog::MEMBER_ROLE
        }
      )
    end
  end
end

# frozen_string_literal: true

module Collection
  class EvaluateAccountJob < ApplicationJob
    queue_as :default

    def perform(account_id, _reference_date_iso = nil)
      account = Account.find(account_id)

      ActsAsTenant.with_tenant(account) do
        settings = CollectionSetting.ensure_for!(account)
        return unless settings.enabled?

        Period.with_pending_receipts
          .where(account: account)
          .includes(:client, :items)
          .find_each do |period_record|
            client = period_record.client
            next if client.archived? || client.onboarding?

            EvaluateClientPeriod.call(
              client: client,
              period_record: period_record,
              settings: settings
            )
          end
      end
    end
  end
end

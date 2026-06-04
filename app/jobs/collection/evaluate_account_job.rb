# frozen_string_literal: true

module Collection
  # Avalia períodos pendentes de uma conta e agenda envios de cobrança.
  class EvaluateAccountJob < ApplicationJob
    queue_as :default

    def perform(account_id, reference_date_iso = nil)
      account = Account.find(account_id)
      reference_date = reference_date_iso&.to_date || Date.current

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
              settings: settings,
              reference_date: reference_date
            )
          end
      end
    end
  end
end

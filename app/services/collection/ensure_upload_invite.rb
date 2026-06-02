# frozen_string_literal: true

module Collection
  class EnsureUploadInvite
    def self.call(client:, period:, account:)
      new(client: client, period: period, account: account).call
    end

    def initialize(client:, period:, account:)
      @client = client
      @period = period.to_date.beginning_of_month
      @account = account
    end

    def call
      existing = UploadInvite.where(client: @client, period: @period).newest_first.find(&:active?)
      return existing if existing

      ActsAsTenant.with_tenant(@account) do
        Clients::CreateUploadInvite.call(
          client: @client,
          period: @period,
          user: nil,
          account: @account
        )
      end
    end
  end
end

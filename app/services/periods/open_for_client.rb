# frozen_string_literal: true

module Periods
  class OpenForClient
    def self.call(client:, period:, account: client.account)
      new(client: client, period: period, account: account).call
    end

    def initialize(client:, period:, account:)
      @client = client
      @account = account
      @period = period.to_date.beginning_of_month
    end

    def call
      FindOrOpen.call(account: @account, client: @client, period: @period)
    end
  end
end

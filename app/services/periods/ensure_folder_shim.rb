# frozen_string_literal: true

module Periods
  class EnsureFolderShim
    def self.call(account:, client:, period:)
      new(account: account, client: client, period: period).call
    end

    def initialize(account:, client:, period:)
      @account = account
      @client = client
      @period = period.to_date.beginning_of_month
    end

    def call
      Folder.find_or_create_by!(
        account: @account,
        client: @client,
        name: @period.strftime("%Y-%m"),
        visible: false
      )
    end
  end
end

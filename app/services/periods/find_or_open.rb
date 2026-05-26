# frozen_string_literal: true

module Periods
  class FindOrOpen
    def self.call(account:, client:, period:)
      new(account: account, client: client, period: period).call
    end

    def initialize(account:, client:, period:)
      @account = account
      @client = client
      @period = period.to_date.beginning_of_month
    end

    def call
      record = Period.find_or_initialize_by(
        account: @account,
        client: @client,
        period: @period
      )

      if record.new_record?
        record.opened_at = Time.current
        record.status = :open
        record.save!
      elsif record.opened_at.blank?
        record.update!(opened_at: record.created_at || Time.current)
      end

      record
    end
  end
end

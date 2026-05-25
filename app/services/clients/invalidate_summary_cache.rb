# frozen_string_literal: true

module Clients
  class InvalidateSummaryCache
    def self.call(client:, period:)
      account_id = client.account_id
      period_key = period.to_date.beginning_of_month
      Rails.cache.delete("client_summary/#{account_id}/#{client.id}/#{period_key}")
    end
  end
end

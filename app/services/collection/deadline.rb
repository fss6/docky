# frozen_string_literal: true

module Collection
  class Deadline
    def self.for(client:, period:)
      new(client: client, period: period).call
    end

    def initialize(client:, period:)
      @client = client
      @period = period.to_date.beginning_of_month
    end

    def call
      day = @client.monthly_deadline_day.clamp(1, 28)
      deadline = @period.change(day: day)
      deadline = deadline.end_of_month if day > deadline.end_of_month.day
      deadline.to_date
    end
  end
end

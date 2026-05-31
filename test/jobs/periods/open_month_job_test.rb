# frozen_string_literal: true

require "test_helper"

module Periods
  class OpenMonthJobTest < ActiveJob::TestCase
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste", price: 0)
      @account = Account.create!(name: "Conta", plan: @plan, active: true)
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente A", tax_id: unique_valid_test_tax_id(account: @account), email: valid_test_client_email)
      end
    end

    test "opens current month for all clients" do
      month = Date.new(2026, 7, 1)

      assert_difference -> { Period.where(client: @client, period: month).count }, 1 do
        OpenMonthJob.perform_now(month)
      end

      record = Period.find_by(client: @client, period: month)
      assert record.open?
    end

    test "job is idempotent for same month" do
      month = Date.new(2026, 8, 1)
      OpenMonthJob.perform_now(month)

      assert_no_difference -> { Period.where(client: @client, period: month).count } do
        OpenMonthJob.perform_now(month)
      end
    end
  end
end

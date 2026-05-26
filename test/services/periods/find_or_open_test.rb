# frozen_string_literal: true

require "test_helper"

module Periods
  class FindOrOpenTest < ActiveSupport::TestCase
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste", price: 0)
      @account = Account.create!(name: "Conta", plan: @plan, active: true)
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente")
      end
    end

    test "creates open period idempotently" do
      ActsAsTenant.with_tenant(@account) do
        month = Date.new(2026, 6, 1)

        first = FindOrOpen.call(account: @account, client: @client, period: month)
        second = FindOrOpen.call(account: @account, client: @client, period: month)

        assert_equal first.id, second.id
        assert first.open?
        assert_equal 1, Period.where(client: @client, period: month).count
      end
    end
  end
end

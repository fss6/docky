# frozen_string_literal: true

require "test_helper"

module Periods
  class LoadMonthlyContextTest < ActiveSupport::TestCase
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

    test "create_if_missing false does not persist period" do
      ActsAsTenant.with_tenant(@account) do
        month = Date.new(2024, 3, 1)

        assert_no_difference -> { Period.count } do
          result = LoadMonthlyContext.call(client: @client, period: month, create_if_missing: false)

          assert_nil result.period_record
          assert_nil result.folder_shim
          assert_empty result.documents_scope
        end
      end
    end

    test "create_if_missing true persists period" do
      ActsAsTenant.with_tenant(@account) do
        month = Date.new(2024, 4, 1)

        assert_difference -> { Period.count }, 1 do
          result = LoadMonthlyContext.call(client: @client, period: month, create_if_missing: true)

          assert result.period_record.present?
          assert result.folder_shim.present?
        end
      end
    end
  end
end

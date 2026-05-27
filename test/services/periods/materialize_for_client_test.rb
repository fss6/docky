# frozen_string_literal: true

require "test_helper"

module Periods
  class MaterializeForClientTest < ActiveSupport::TestCase
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste", price: 0)
      @account = Account.create!(name: "Conta", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Owner",
        email: "owner-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente")
      end
    end

    test "creates open period for current month" do
      ActsAsTenant.with_tenant(@account) do
        month = Date.current.beginning_of_month
        result = MaterializeForClient.call(client: @client, period: month, user: @user)

        assert result.created
        assert result.period_record.open?
        assert Folder.exists?(client: @client, name: month.strftime("%Y-%m"), visible: false)
      end
    end

    test "creates closed period for past month" do
      ActsAsTenant.with_tenant(@account) do
        month = (Date.current.beginning_of_month - 2.months)
        result = MaterializeForClient.call(client: @client, period: month, user: @user)

        assert result.created
        assert result.period_record.closed?
        assert AuditEvent.exists?(event_type: "period.created_retroactive", subject: result.period_record)
      end
    end

    test "creates open period for future month" do
      ActsAsTenant.with_tenant(@account) do
        month = Date.current.beginning_of_month + 2.months
        result = MaterializeForClient.call(client: @client, period: month, user: @user)

        assert result.created
        assert result.period_record.open?
      end
    end

    test "does not duplicate when period already exists" do
      ActsAsTenant.with_tenant(@account) do
        month = Date.current.beginning_of_month + 1.month
        first = MaterializeForClient.call(client: @client, period: month, user: @user)

        assert_no_difference -> { Period.where(client: @client, period: month).count } do
          second = MaterializeForClient.call(client: @client, period: month, user: @user)

          assert_not second.created
          assert_equal first.period_record.id, second.period_record.id
        end
      end
    end
  end
end

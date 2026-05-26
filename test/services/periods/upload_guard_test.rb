# frozen_string_literal: true

require "test_helper"

module Periods
  class UploadGuardTest < ActiveSupport::TestCase
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
        @period = Period.create!(account: @account, client: @client, period: Date.current.beginning_of_month)
      end
    end

    test "allows upload when period is open" do
      result = UploadGuard.call(period: @period)
      assert result.allowed
    end

    test "blocks upload when period is closed" do
      Periods::Close.call(period: @period, user: @user)
      result = UploadGuard.call(period: @period.reload)
      assert_not result.allowed
      assert_match "encerrada", result.reason
    end
  end
end

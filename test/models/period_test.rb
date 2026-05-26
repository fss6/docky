# frozen_string_literal: true

require "test_helper"

class PeriodTest < ActiveSupport::TestCase
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

  test "normalizes period to beginning of month" do
    ActsAsTenant.with_tenant(@account) do
      record = Period.create!(account: @account, client: @client, period: Date.new(2026, 5, 15))
      assert_equal Date.new(2026, 5, 1), record.period
      assert record.open?
      assert record.opened_at.present?
    end
  end

  test "closed? reflects status" do
    user = User.create!(
      account: @account,
      name: "Owner",
      email: "owner-#{SecureRandom.hex(4)}@example.com",
      role: :owner,
      active: true,
      password: "password123",
      password_confirmation: "password123"
    )
    ActsAsTenant.with_tenant(@account) do
      record = Period.create!(account: @account, client: @client, period: Date.current.beginning_of_month)
      Periods::Close.call(period: record, user: user)
      assert record.reload.closed?
    end
  end
end

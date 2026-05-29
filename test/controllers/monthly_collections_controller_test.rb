# frozen_string_literal: true

require "test_helper"

class MonthlyCollectionsControllerTest < ActionDispatch::IntegrationTest
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
      @client = Client.create!(account: @account, name: "Cliente Alpha")
    end
    @period = Date.new(2026, 4, 1)
  end

  setup do
    sign_in @user
  end

  test "index redirects to clients index" do
    get monthly_collections_url

    assert_redirected_to clients_path
  end

  test "show redirects to clients index" do
    get monthly_collection_url(@period.strftime("%Y-%m"))

    assert_redirected_to clients_path
  end

  test "close redirects to clients index" do
    ActsAsTenant.with_tenant(@account) do
      Period.create!(account: @account, client: @client, period: @period)
    end

    patch close_monthly_collection_url(@period.strftime("%Y-%m"))

    assert_redirected_to clients_path
  end

  test "destroy redirects to clients index" do
    ActsAsTenant.with_tenant(@account) do
      Period.create!(account: @account, client: @client, period: @period)
    end

    delete monthly_collection_url(@period.strftime("%Y-%m"))

    assert_redirected_to clients_path
  end
end

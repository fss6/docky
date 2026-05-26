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
  end

  setup do
    sign_in @user
    patch current_client_url, params: { client_id: @client.id }
    @period = Date.new(2026, 4, 1)
  end

  test "should close competency" do
    ActsAsTenant.with_tenant(@account) do
      checklist = Period.create!(account: @account, client: @client, period: @period)

      patch close_monthly_collection_url(@period.strftime("%Y-%m"))

      assert_redirected_to monthly_collection_path(@period.strftime("%Y-%m"))
      assert checklist.reload.closed?
    end
  end

  test "should remove competency and redirect to list" do
    ActsAsTenant.with_tenant(@account) do
      checklist = Period.create!(account: @account, client: @client, period: @period)

      assert_difference -> { Period.where(id: checklist.id).count }, -1 do
        delete monthly_collection_url(@period.strftime("%Y-%m"))
      end

      assert_redirected_to monthly_collections_path
      follow_redirect!
      assert_includes response.body, "Competência removida com sucesso."
      assert_not Period.exists?(checklist.id)
    end
  end
end

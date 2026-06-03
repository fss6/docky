# frozen_string_literal: true

require "test_helper"

class CollectionPanelControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @account = accounts(:one)
    @client = clients(:alpha)
    ActsAsTenant.with_tenant(@account) do
      CollectionSetting.ensure_for!(@account)
      @period = Period.create!(
        account: @account,
        client: @client,
        period: Date.new(2026, 5, 1),
        status: :open,
        opened_at: Time.current
      )
      @period.items.create!(name_snapshot: "Extrato", match_terms: ["extrato"], state: :pending)
    end
  end

  test "index renders without period param" do
    get collection_panel_path
    assert_response :success
    assert_select "h1", text: /Painel de pendências/
    assert_select "a", text: "Em atraso"
  end

  test "index filters by status" do
    get collection_panel_path, params: { status: "late" }
    assert_response :success
  end

  test "index selects row by period_id" do
    get collection_panel_path, params: { period_id: @period.id }
    assert_response :success
    assert_select "h2", text: @client.name
  end
end

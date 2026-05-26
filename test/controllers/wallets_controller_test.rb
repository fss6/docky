# frozen_string_literal: true

require "test_helper"

class WalletsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)

    @account = users(:owner).account
    @owner = users(:owner)
    @period = Date.current.beginning_of_month
    @period_name = @period.strftime("%Y-%m")
    @alpha = clients(:alpha)
    @beta = clients(:beta)

    alpha_checklist = CompetencyChecklist.create!(
      account: @account,
      client: @alpha,
      period: @period
    )
    beta_checklist = CompetencyChecklist.create!(
      account: @account,
      client: @beta,
      period: @period
    )

    CompetencyChecklistItem.create!(
      competency_checklist: alpha_checklist,
      name_snapshot: "DARF IRPJ",
      state: :pending
    )
    CompetencyChecklistItem.create!(
      competency_checklist: beta_checklist,
      name_snapshot: "DAS",
      state: :validated,
      validated_by_user: @owner,
      validated_at: Time.current
    )

    alpha_folder = Folder.create!(account: @account, client: @alpha, name: @period_name, visible: false)
    Document.create!(
      account: @account,
      user: @owner,
      folder: alpha_folder,
      status: :processed,
      created_at: 7.days.ago,
      updated_at: 7.days.ago
    )
  end

  test "should get index" do
    get wallet_url
    assert_response :success
    assert_includes response.body, "Carteira"
    assert_includes response.body, @alpha.name
    assert_includes response.body, @beta.name
  end

  test "should filter by critical status" do
    get wallet_url, params: { period: @period_name, status: "critical" }
    assert_response :success
    table_body = css_select("tbody").first&.text.to_s
    assert_includes table_body, @alpha.name
    assert_not_includes table_body, @beta.name
  end

  test "should filter only pending rows" do
    get wallet_url, params: { period: @period_name, only_pending: "1" }
    assert_response :success
    table_body = css_select("tbody").first&.text.to_s
    assert_includes table_body, @alpha.name
    assert_not_includes table_body, @beta.name
  end
end

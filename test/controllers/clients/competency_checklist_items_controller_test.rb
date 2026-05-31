# frozen_string_literal: true

require "test_helper"

module Clients
  class CompetencyChecklistItemsControllerTest < ActionDispatch::IntegrationTest
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste", price: 0)
      @account = Account.create!(name: "Conta Teste", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Owner Teste",
        email: "owner-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente Teste", tax_id: unique_valid_test_tax_id(account: @account), email: valid_test_client_email)
        @period = Date.current.beginning_of_month
        @period_param = @period.strftime("%Y-%m")
        @checklist = CompetencyChecklist.create!(account: @account, client: @client, period: @period)
        @item = CompetencyChecklistItem.create!(
          competency_checklist: @checklist,
          name_snapshot: "DARF IRPJ",
          state: :pending
        )
        @folder = Folder.create!(account: @account, client: @client, name: @period_param, visible: false)
        @document = Document.create!(
          account: @account,
          user: @user,
          folder: @folder,
          client: @client,
          collection_period: @period,
          status: :processed
        )
      end
      sign_in @user
    end

    test "mark_validated marks item without document" do
      patch mark_validated_client_competency_checklist_item_path(@client, @item, period: @period_param),
            headers: { Accept: "text/vnd.turbo-stream.html" }

      assert_response :success
      @item.reload
      assert @item.validated?
      assert @item.last_document_id.blank?
      assert_match "client_checklist_panel", response.body
      assert_match "client_executive_summary", response.body
      assert_match "Item conferido", response.body
      assert_match 'turbo-frame id="client_checklist_panel"', response.body

      summary = MonthlySummary.new(client: @client, checklist: @checklist, period: @period).call
      assert_equal 0, summary[:pending_count]
    end

    test "mark_pending reopens validated item without document" do
      ActsAsTenant.with_tenant(@account) do
        @item.mark_validated!(user: @user)
      end

      patch mark_pending_client_competency_checklist_item_path(@client, @item, period: @period_param),
            headers: { Accept: "text/vnd.turbo-stream.html" }

      assert_response :success
      @item.reload
      assert @item.awaiting_receipt?
      assert_match "Item reaberto como pendente", response.body
      assert_match "Pendente", response.body
      assert_no_match "Conferido manualmente", response.body
    end

    test "mark_pending blocked when item has linked document" do
      ActsAsTenant.with_tenant(@account) do
        @item.update!(
          last_document: @document,
          received_at: Time.current,
          state: :validated,
          validated_by_user: @user,
          validated_at: Time.current
        )
      end

      patch mark_pending_client_competency_checklist_item_path(@client, @item, period: @period_param),
            headers: { Accept: "text/vnd.turbo-stream.html" }

      assert_response :unprocessable_entity
      @item.reload
      assert @item.validated?
      assert_equal @document.id, @item.last_document_id
      assert_match "Desvincule o documento antes de reabrir este item", response.body
    end
  end
end

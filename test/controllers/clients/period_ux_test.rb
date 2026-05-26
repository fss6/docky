# frozen_string_literal: true

require "test_helper"

module Clients
  class PeriodUxTest < ActionDispatch::IntegrationTest
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
        @client = Client.create!(account: @account, name: "Cliente Teste")
        @period = Date.current.beginning_of_month
        @period_param = @period.strftime("%Y-%m")
        @checklist = CompetencyChecklist.create!(account: @account, client: @client, period: @period)
        @client.client_checklist_items.create!(account: @account, name: "DARF", position: 1, active: true)
        @client.client_checklist_items.create!(account: @account, name: "DAS", position: 2, active: true)
      end
      sign_in @user
    end

    test "show without period redirects to current month" do
      get client_path(@client)

      assert_redirected_to client_path(@client, period: @period_param)
    end

    test "checklist tab shows compact period navigator without status chips" do
      get client_path(@client, aba: "checklist", period: @period_param)

      assert_response :success
      assert_match 'aria-label="Competência"', response.body
      assert_select 'button[aria-label*="Escolher competência"]'
      assert_select "button.bg-sky-50.border-sky-200"
      assert_select "button.bg-sky-50 svg.text-sky-600"
      assert_select "button.bg-sky-50 span.text-sky-800", text: /#{Regexp.escape(PeriodFormatting.display_label(@period))}/
      assert_no_match ">Atual<", response.body
      assert_no_match ">Aberta<", response.body
      assert_no_match ">Encerrada<", response.body
      assert_match "Montar checklist deste mês", response.body
      assert_no_match "Iniciar próximo mês", response.body
      assert_no_match ">Ir<", response.body
      assert_no_match "Você está vendo os documentos", response.body
      assert_match "Mês em andamento", response.body
      assert_no_match "Mês atual", response.body
      assert_no_match "Ir para", response.body
    end

    test "past month shows go to current month action in navigator" do
      past_period = (@period - 1.month).strftime("%Y-%m")
      ActsAsTenant.with_tenant(@account) do
        past_checklist = CompetencyChecklist.create!(
          account: @account,
          client: @client,
          period: @period - 1.month
        )
        Periods::Close.call(period: past_checklist, user: @user)
      end

      get client_path(@client, aba: "checklist", period: past_period)

      assert_response :success
      go_to_label = "Ir para #{PeriodFormatting.display_label(@period)}"
      assert_select "div.border-zinc-200 a", text: go_to_label
      assert_no_match "Mês em andamento", response.body
      assert_no_match "Mês atual", response.body
      assert_select "button.border-transparent"
      assert_select "button.border-transparent svg.text-zinc-400"
      assert_select "button.bg-sky-50", count: 0
      assert_match "Reabrir competência", response.body
      assert_match "Competência encerrada", response.body
      assert_no_match ">Retroativa<", response.body
      assert_select "span.text-zinc-900", text: /#{Regexp.escape(PeriodFormatting.display_label(@period - 1.month))}/
    end

    test "period navigator has prev and next month links" do
      get client_path(@client, aba: "checklist", period: @period_param)

      prev_param = (@period - 1.month).strftime("%Y-%m")
      next_param = (@period + 1.month).strftime("%Y-%m")

      assert_select "a[href=?]", client_path(@client, aba: "checklist", period: prev_param)
      assert_select "a[href=?]", client_path(@client, aba: "checklist", period: next_param)
    end

    test "sync_to_month builds checklist via turbo stream" do
      post sync_to_month_client_checklist_items_path(@client, period: @period_param),
           headers: { Accept: "text/vnd.turbo-stream.html" }

      assert_response :success
      assert_equal 2, @checklist.items.count
      assert_match "client_checklist_panel", response.body
      assert_match "Checklist montado para o mês", response.body
    end

    test "historico tab shows period activity timeline" do
      ActsAsTenant.with_tenant(@account) do
        Periods::Close.call(period: @checklist, user: @user)
      end

      get client_path(@client, aba: "historico", period: @period_param)

      assert_response :success
      assert_match "Histórico de", response.body
      assert_match "Competência encerrada", response.body
    end

    test "past month with no pending items shows month completed badge" do
      past_period = (@period - 1.month).strftime("%Y-%m")
      ActsAsTenant.with_tenant(@account) do
        past_checklist = CompetencyChecklist.create!(
          account: @account,
          client: @client,
          period: @period - 1.month
        )
        item = past_checklist.items.create!(name_snapshot: "DARF", state: :validated, validated_at: Time.current)
        item.mark_validated!(user: @user)
      end

      get client_path(@client, aba: "checklist", period: past_period)

      assert_response :success
      assert_match "Mês concluído", response.body
    end
  end
end

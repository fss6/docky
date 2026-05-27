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
      assert_match "Últimas 10 atividades", response.body
      assert_match "Competência encerrada", response.body
    end

    test "missing past month shows CTA without creating period" do
      past_period = (@period - 2.months).strftime("%Y-%m")

      ActsAsTenant.with_tenant(@account) do
        assert_not Period.exists?(client: @client, period: @period - 2.months)
      end

      assert_no_difference -> { Period.count } do
        get client_path(@client, aba: "checklist", period: past_period)
      end

      assert_response :success
      assert_match "Competência não aberta", response.body
      assert_match "Criar competência retroativa", response.body
      assert_no_match "Montar checklist deste mês", response.body
    end

    test "open_period creates current month open" do
      ActsAsTenant.with_tenant(@account) do
        @checklist.destroy!
      end

      assert_difference -> { Period.count }, 1 do
        post open_period_client_path(@client), params: { period: @period_param, aba: "documentos" }
      end

      assert_redirected_to client_path(@client, aba: "documentos", period: @period_param)
      ActsAsTenant.with_tenant(@account) do
        record = Period.find_by!(client: @client, period: @period)
        assert record.open?
      end
    end

    test "open_period creates past month closed" do
      past = @period - 2.months
      past_param = past.strftime("%Y-%m")

      assert_difference -> { Period.count }, 1 do
        post open_period_client_path(@client), params: { period: past_param, aba: "checklist" }
      end

      ActsAsTenant.with_tenant(@account) do
        record = Period.find_by!(client: @client, period: past)
        assert record.closed?
      end
    end

    test "future month shows CTA to open period early" do
      future_param = (@period + 2.months).strftime("%Y-%m")

      assert_no_difference -> { Period.count } do
        get client_path(@client, period: future_param)
      end

      assert_response :success
      assert_match "Competência futura", response.body
      assert_match "Abrir competência antecipada", response.body
    end

    test "open_period creates future month open" do
      future = @period + 2.months
      future_param = future.strftime("%Y-%m")

      assert_difference -> { Period.count }, 1 do
        post open_period_client_path(@client), params: { period: future_param, aba: "documentos" }
      end

      ActsAsTenant.with_tenant(@account) do
        record = Period.find_by!(client: @client, period: future)
        assert record.open?
      end
    end

    test "upload invite without period redirects to open competency" do
      past_param = (@period - 3.months).strftime("%Y-%m")

      assert_no_difference -> { UploadInvite.count } do
        post client_upload_invites_path(@client, period: past_param)
      end

      assert_redirected_to client_path(@client, aba: "convites", period: past_param)
      assert_equal "Abra a competência antes de gerar o link de upload.", flash[:alert]
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

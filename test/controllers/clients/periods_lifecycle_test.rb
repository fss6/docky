# frozen_string_literal: true

require "test_helper"

module Clients
  class PeriodsLifecycleTest < ActionDispatch::IntegrationTest
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
        @period_record = Period.create!(account: @account, client: @client, period: @period)
        @folder = Folder.create!(account: @account, client: @client, name: @period_param, visible: false)
      end
      sign_in @user
    end

    test "close_period marks competency closed" do
      patch close_period_client_path(@client, period: @period_param, aba: "documentos")

      assert_redirected_to client_path(@client, aba: "documentos", period: @period_param)
      assert @period_record.reload.closed?
    end

    test "reopen_period marks competency open" do
      Periods::Close.call(period: @period_record, user: @user)

      patch reopen_period_client_path(@client, period: @period_param, aba: "documentos")

      assert_redirected_to client_path(@client, aba: "documentos", period: @period_param)
      assert @period_record.reload.open?
    end

    test "internal upload blocked when period closed" do
      Periods::Close.call(period: @period_record, user: @user)
      file = fixture_file_upload("test/fixtures/files/sample.txt", "text/plain")

      post client_documents_path(@client, period: @period_param),
           params: { document: { file: file } }

      assert_redirected_to client_path(@client, aba: "documentos", period: @period_param)
      follow_redirect!
      assert_match "encerrada", response.body
    end
  end
end

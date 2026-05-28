# frozen_string_literal: true

require "test_helper"

module Clients
  class ArchivedAccessTest < ActionDispatch::IntegrationTest
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Archived Access", price: 0)
      @account = Account.create!(name: "Archived Account", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Owner Archived",
        email: "owner-archived-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente Arquivado", status: :active)
        @period = Date.current.beginning_of_month
        CompetencyChecklist.create!(account: @account, client: @client, period: @period)
        Clients::Archive.call(client: @client, user: @user)
        @client.reload
      end
      sign_in @user
    end

    test "show archived client is readable" do
      get client_path(@client, period: @period.strftime("%Y-%m"))

      assert_response :success
      assert_match "apenas consulta", response.body
    end

    test "update archived client is blocked" do
      patch client_path(@client), params: {
        client: { name: "Nome alterado" }
      }

      assert_redirected_to client_path(@client)
      assert_equal "Cliente Arquivado", @client.reload.name
    end

    test "archived client appears in clients index with badge" do
      get clients_path

      assert_response :success
      assert_match "Cliente Arquivado", response.body
      assert_match "Arquivado", response.body
    end

    test "unarchive restores client to active list" do
      post unarchive_client_path(@client)

      assert_redirected_to client_path(@client)
      assert_not @client.reload.archived?

      get clients_path
      assert_response :success
      assert_match "Cliente Arquivado", response.body
    end
  end
end

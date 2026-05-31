# frozen_string_literal: true

require "test_helper"

module Clients
  class MonthlySummaryTest < ActiveSupport::TestCase
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste", price: 0)
      @account = Account.create!(name: "Conta", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Contador",
        email: "owner-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente", tax_id: unique_valid_test_tax_id(account: @account), email: valid_test_client_email)
        @period_date = Date.new(2026, 5, 1)
        @period_record = Period.create!(account: @account, client: @client, period: @period_date)
        @checklist = @period_record
        @folder = Folder.create!(account: @account, client: @client, name: "2026-05", visible: false)
      end
    end

    test "last received uses most recent document regardless of upload source" do
      ActsAsTenant.with_tenant(@account) do
        travel_to Time.zone.local(2026, 5, 10, 12, 0, 0) do
          Document.create!(
            account: @account,
            user: @user,
            folder: @folder,
            client: @client,
            period: @period_record,
            collection_period: @period_date,
            status: :pending,
            metadata: { "upload_source" => "public_link" }
          )
        end

        travel_to Time.zone.local(2026, 5, 12, 15, 0, 0) do
          Document.create!(
            account: @account,
            user: @user,
            folder: @folder,
            client: @client,
            period: @period_record,
            collection_period: @period_date,
            status: :pending,
            metadata: { "upload_source" => "internal_upload" }
          )
        end

        summary = MonthlySummary.new(
          client: @client,
          checklist: @checklist,
          period: @period_date,
          period_record: @period_record
        ).call

        assert_match(/\Ahá /, summary[:last_received_label])
        assert_equal "via conta", summary[:last_received_source_label]
      end
    end

    test "last received is empty when there are no documents" do
      ActsAsTenant.with_tenant(@account) do
        summary = MonthlySummary.new(
          client: @client,
          checklist: @checklist,
          period: @period_date,
          period_record: @period_record
        ).call

        assert_equal "—", summary[:last_received_label]
        assert_nil summary[:last_received_source_label]
      end
    end
  end
end

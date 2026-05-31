# frozen_string_literal: true

require "test_helper"

module AuditEvents
  class RecordDocumentReceivedTest < ActiveSupport::TestCase
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
        @period_record = Period.create!(account: @account, client: @client, period: Date.current.beginning_of_month)
        @folder = Folder.create!(account: @account, client: @client, name: Date.current.strftime("%Y-%m"), visible: false)
      end
    end

    test "creates audit event with period metadata" do
      ActsAsTenant.with_tenant(@account) do
        document = Document.create!(
          account: @account,
          user: @user,
          folder: @folder,
          client: @client,
          period: @period_record,
          collection_period: @period_record.period,
          status: :pending,
          metadata: { "upload_source" => "internal_upload" }
        )

        assert_difference -> { AuditEvent.where(event_type: "document.received", subject: document).count }, 1 do
          RecordDocumentReceived.call(document: document, user: @user)
        end

        event = AuditEvent.find_by!(event_type: "document.received", subject: document)
        metadata = event.metadata.with_indifferent_access
        assert_equal @period_record.period.strftime("%Y-%m"), metadata[:period]
        assert_equal @client.id, metadata[:client_id]
      end
    end
  end
end

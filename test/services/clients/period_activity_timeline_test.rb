# frozen_string_literal: true

require "test_helper"

module Clients
  class PeriodActivityTimelineTest < ActiveSupport::TestCase
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
        @client = Client.create!(account: @account, name: "Cliente")
        @period_date = Date.new(2026, 5, 1)
        @period_record = Period.create!(account: @account, client: @client, period: @period_date)
        @folder = Folder.create!(account: @account, client: @client, name: "2026-05", visible: false)
      end
    end

    test "includes audit events for the period" do
      ActsAsTenant.with_tenant(@account) do
        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "period.closed",
          subject: @period_record,
          metadata: { client_id: @client.id, period: "2026-05" }
        )

        entries = PeriodActivityTimeline.call(
          client: @client,
          period: @period_date,
          period_record: @period_record
        )

        assert entries.any? { |e| e.title == "Competência encerrada" && e.actor == "Contador" }
      end
    end

    test "includes legacy documents without audit events" do
      ActsAsTenant.with_tenant(@account) do
        document = Document.create!(
          account: @account,
          user: @user,
          folder: @folder,
          client: @client,
          period: @period_record,
          collection_period: @period_date,
          status: :pending,
          metadata: { "upload_source" => "internal_upload" }
        )
        document.file.attach(
          io: StringIO.new("test"),
          filename: "nota.pdf",
          content_type: "application/pdf"
        )

        entries = PeriodActivityTimeline.call(
          client: @client,
          period: @period_date,
          period_record: @period_record
        )

        doc_entry = entries.find { |e| e.title == "Arquivo recebido" && e.description.include?("nota.pdf") }
        assert doc_entry
        assert_includes doc_entry.description, "upload manual"
      end
    end

    test "excludes events from other periods" do
      ActsAsTenant.with_tenant(@account) do
        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "period.closed",
          subject: @period_record,
          metadata: { client_id: @client.id, period: "2026-04" }
        )

        entries = PeriodActivityTimeline.call(
          client: @client,
          period: @period_date,
          period_record: @period_record
        )

        assert_not entries.any? { |e| e.title == "Competência encerrada" }
      end
    end
  end
end

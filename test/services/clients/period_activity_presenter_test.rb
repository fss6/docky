# frozen_string_literal: true

require "test_helper"

module Clients
  class PeriodActivityPresenterTest < ActiveSupport::TestCase
    def setup_fixtures
    end

    def teardown_fixtures
    end

    test "formats document received event" do
      event = AuditEvent.new(
        event_type: "document.received",
        metadata: {
          "filename" => "extrato.pdf",
          "upload_source" => "public_link"
        }
      )

      presenter = PeriodActivityPresenter.new(event)

      assert_equal "Arquivo recebido", presenter.title
      assert_equal "extrato.pdf · via portal", presenter.description
      assert_equal :document, presenter.category
    end

    test "formats period closed with month/year label" do
      event = AuditEvent.new(
        event_type: "period.closed",
        metadata: { "period" => "2026-05" }
      )

      presenter = PeriodActivityPresenter.new(event)

      assert_equal "Maio/2026", presenter.description
    end

    test "formats checklist validation with item name in metadata" do
      event = AuditEvent.new(
        event_type: "checklist_item.marked_validated",
        metadata: { "item_name" => "DARF", "period" => "2026-05" }
      )

      presenter = PeriodActivityPresenter.new(event)

      assert_equal "Item validado", presenter.title
      assert_equal "DARF", presenter.description
    end
  end
end

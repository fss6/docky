# frozen_string_literal: true

require "test_helper"

module AuditLog
  class PresenterTest < ActiveSupport::TestCase
    LogRow = Struct.new(
      :row_id, :source, :created_at, :actor_name, :verb, :item_type, :item_id, :payload,
      keyword_init: true
    )

    test "presents audit data row with formatted action and details" do
      folder = folders(:one)
      audit = Audit.new(
        id: 99,
        action: "update",
        auditable_type: "Folder",
        auditable_id: folder.id,
        audited_changes: { "name" => ["Antes", "Depois"] }
      )

      log = LogRow.new(
        row_id: 99,
        source: "audit",
        created_at: Time.current,
        actor_name: "Owner",
        verb: "update",
        item_type: "Folder",
        item_id: folder.id,
        payload: audit.audited_changes.to_yaml
      )

      presenter = Presenter.new(
        log,
        audits_by_id: { 99 => audit },
        subject_labels: { "Folder:#{folder.id}" => "Pasta · #{folder.name}" }
      )

      assert_equal "Atualizado", presenter.action_label
      assert_equal "Pasta · #{folder.name}", presenter.item_label
      assert_includes presenter.details_summary, "Nome:"
    end

    test "presents event row using preloaded audit event" do
      event = AuditEvent.new(
        id: 42,
        event_type: "document.tag_added",
        metadata: { "tag" => "fiscal" }
      )

      log = LogRow.new(
        row_id: 42,
        source: "event",
        created_at: Time.current,
        actor_name: "Owner",
        verb: "document.tag_added",
        item_type: "Document",
        item_id: 1,
        payload: { "tag" => "fiscal" }.to_json
      )

      presenter = Presenter.new(
        log,
        audit_events_by_id: { 42 => event }
      )

      assert_equal "Tag adicionada", presenter.action_label
      assert_equal "fiscal", presenter.details_summary
    end

    test "falls back item label when subject missing" do
      log = LogRow.new(
        row_id: 1,
        source: "event",
        created_at: Time.current,
        actor_name: nil,
        verb: "client.created",
        item_type: "Client",
        item_id: 999_999,
        payload: "{}"
      )

      presenter = Presenter.new(log)

      assert_equal "Cliente #999999", presenter.item_label
      assert_equal "Sistema", presenter.actor_name
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module AuditLog
  class AuditedChangesFormatterTest < ActiveSupport::TestCase
    test "formats folder name update" do
      formatter = AuditedChangesFormatter.new(
        auditable_type: "Folder",
        action: "update",
        audited_changes: { "name" => ["Antigo", "Novo"] }
      )

      assert_equal "Atualizado", formatter.action_label
      assert_includes formatter.summary, "Nome:"
      assert_includes formatter.summary, "Antigo"
      assert_includes formatter.summary, "Novo"
    end

    test "formats folder visible create" do
      formatter = AuditedChangesFormatter.new(
        auditable_type: "Folder",
        action: "create",
        audited_changes: { "visible" => [false, true] }
      )

      assert_equal "Criado", formatter.action_label
      assert_includes formatter.summary, "Visível:"
      assert_includes formatter.summary, "Sim"
    end

    test "parses yaml audited changes string" do
      yaml = { "name" => ["A", "B"] }.to_yaml

      formatter = AuditedChangesFormatter.new(
        auditable_type: "Folder",
        action: "update",
        audited_changes: yaml
      )

      assert_includes formatter.summary, "A"
      assert_includes formatter.summary, "B"
    end
  end
end

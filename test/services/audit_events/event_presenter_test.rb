# frozen_string_literal: true

require "test_helper"

module AuditEvents
  class EventPresenterTest < ActiveSupport::TestCase
    test "formats document received event" do
      event = AuditEvent.new(
        event_type: "document.received",
        metadata: {
          "filename" => "extrato.pdf",
          "upload_source" => "public_link"
        }
      )

      presenter = EventPresenter.new(event)

      assert_equal "Arquivo recebido", presenter.title
      assert_equal "extrato.pdf · via portal", presenter.description
    end

    test "formats period closed with month year label" do
      event = AuditEvent.new(
        event_type: "period.closed",
        metadata: { "period" => "2026-05" }
      )

      presenter = EventPresenter.new(event)

      assert_equal "Competência encerrada", presenter.title
      assert_equal "Maio/2026", presenter.description
    end

    test "formats document moved between folders" do
      account = accounts(:one)
      client = clients(:alpha)
      from_folder = Folder.create!(account: account, client: client, name: "Pasta origem", visible: true)
      to_folder = Folder.create!(account: account, client: client, name: "Pasta destino", visible: true)

      event = AuditEvent.new(
        event_type: "document.moved",
        metadata: {
          "from_folder_id" => from_folder.id,
          "to_folder_id" => to_folder.id
        }
      )

      presenter = EventPresenter.new(event)

      assert_equal "Arquivo movido", presenter.title
      assert_includes presenter.description, "Pasta origem"
      assert_includes presenter.description, "Pasta destino"
    end

    test "formats document tag added" do
      event = AuditEvent.new(
        event_type: "document.tag_added",
        metadata: { "tag" => "urgente" }
      )

      presenter = EventPresenter.new(event)

      assert_equal "Tag adicionada", presenter.title
      assert_equal "urgente", presenter.description
    end

    test "formats permission grant updated" do
      event = AuditEvent.new(
        event_type: "permission_grant.updated",
        metadata: {
          "capability_key" => "clients.manage",
          "granted" => true,
          "role" => "member"
        }
      )

      presenter = EventPresenter.new(event)

      assert_equal "Permissões atualizadas", presenter.title
      assert_includes presenter.description, "clients.manage"
      assert_includes presenter.description, "concedida"
    end
  end
end

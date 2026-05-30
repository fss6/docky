# frozen_string_literal: true

require "test_helper"

class AuditsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
  end

  test "index loads successfully" do
    get audits_path

    assert_response :success
    assert_includes response.body, "Auditoria"
  end

  test "index shows friendly labels for events and data audits" do
    account = accounts(:one)
    user = users(:owner)
    folder = folders(:one)
    client = folder.client

    period = Period.create!(
      account: account,
      client: client,
      period: Date.new(2026, 5, 1)
    )

    AuditEvents::Recorder.call(
      account: account,
      user: user,
      event_type: "period.closed",
      subject: period,
      metadata: { client_id: client.id, period: "2026-05" }
    )

    ActsAsTenant.with_tenant(account) do
      Audited.audit_class.as_user(user) do
        folder.update!(name: "Pasta renomeada para auditoria")
      end
    end

    get audits_path

    assert_response :success
    assert_includes response.body, "Competência encerrada"
    assert_includes response.body, "Atualizado"
    assert_includes response.body, "Maio/2026"
  end
end

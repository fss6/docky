# frozen_string_literal: true

require "test_helper"

module Collection
  class EmailPlaygroundTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      ActsAsTenant.current_tenant = @account
      Collection::SeedDefaultSteps.call(account: @account) unless @account.collection_steps.exists?
      @step = @account.collection_steps.find_by!(offset_days: -3)
    end

    test "preview replaces placeholders with client data" do
      preview = EmailPlayground.preview(
        step: @step,
        client: @client,
        account: @account,
        subject_template: "Olá {cliente}",
        body_template: "Pendente:\n{documentos_faltantes}\n{link_upload}",
        recipient: "owner@example.com"
      )

      assert_includes preview.subject, "[TESTE]"
      assert_includes preview.subject, @client.name
      assert_includes preview.body, "http"
      assert_includes preview.html, "Dokivo"
      assert_includes preview.html, "Enviar documentos"
      assert_includes preview.html, "Cancelar lembretes"
      assert_includes preview.html, "<table"
    end

    test "preview uses fallback pending items when none exist" do
      preview = EmailPlayground.preview(
        step: @step,
        client: @client,
        account: @account,
        subject_template: "Assunto",
        body_template: "{documentos_faltantes}",
        recipient: "owner@example.com"
      )

      assert_includes preview.body, "Nota fiscal"
      assert_includes preview.body, "Extrato bancário"
    end

    test "internal alert preview uses internal mailer layout" do
      internal = @account.collection_steps.find(&:kind_internal_alert?)
      skip "no internal step" unless internal

      preview = EmailPlayground.preview(
        step: internal,
        client: @client,
        account: @account,
        subject_template: "Alerta {cliente}",
        body_template: "Pendente: {documentos_faltantes}",
        recipient: "owner@example.com"
      )

      assert_includes preview.subject, "[TESTE]"
      assert_includes preview.html, "Dokivo"
      assert_includes preview.html, "<table"
      assert_not_includes preview.html, "Cancelar lembretes"
    end

    test "send_test delivers to recipient" do
      assert_emails 1 do
        result = EmailPlayground.send_test!(
          step: @step,
          client: @client,
          account: @account,
          subject_template: @step.email_subject_template,
          body_template: @step.email_body_template,
          recipient: "owner@example.com"
        )
        assert result.success, result.error
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal [ "owner@example.com" ], mail.to
    end

    test "returns failure when smtp not configured" do
      ActionMailerDelivery.stub(:enabled?, false) do
        result = EmailPlayground.send_test!(
          step: @step,
          client: @client,
          account: @account,
          subject_template: "Assunto",
          body_template: "Corpo",
          recipient: "owner@example.com"
        )
        assert_not result.success
        assert_includes result.error, "SMTP"
      end
    end
  end
end

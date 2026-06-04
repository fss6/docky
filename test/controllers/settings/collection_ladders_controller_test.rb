# frozen_string_literal: true

require "test_helper"

class Settings::CollectionLaddersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
    ActsAsTenant.with_tenant(accounts(:one)) do
      @setting = CollectionSetting.ensure_for!(accounts(:one))
      Collection::SeedDefaultSteps.call(account: accounts(:one)) unless accounts(:one).collection_steps.exists?
      @steps = accounts(:one).collection_steps.ordered.to_a
    end
  end

  test "edit renders without platform status cards" do
    get edit_settings_collection_ladder_path
    assert_response :success
    assert_select "h1", text: /Lembretes automáticos/
    assert_select "input[type=submit][value=?]", "Salvar comportamento"
    assert_no_match(/E-mail \(SMTP\)/, response.body)
    assert_no_match(/WhatsApp \(Dokivo\)/, response.body)
    assert_match(/-3d/, response.body)
    assert_match(/antes do prazo/, response.body)
    assert_match(/Linha do tempo/, response.body)
    assert_select "input[type=submit][value=?]", "Salvar e-mail"
    assert_select "input[type=submit][value=?]", "Salvar WhatsApp"
  end

  test "update behavior only" do
    patch settings_collection_ladder_path, params: {
      section: "behavior",
      collection_setting: {
        enabled: true,
        quiet_hours_start: "08:00",
        quiet_hours_end: "19:00",
        timezone: "America/Sao_Paulo"
      }
    }
    assert_redirected_to edit_settings_collection_ladder_path
    assert_equal "Comportamento atualizado.", flash[:notice]

    setting = collection_settings(:one).reload
    assert setting.enabled?
    assert_equal "08:00", setting.quiet_hours_start.strftime("%H:%M")
    assert_equal "19:00", setting.quiet_hours_end.strftime("%H:%M")
  end

  test "edit does not expose max messages per day control" do
    get edit_settings_collection_ladder_path
    assert_response :success
    assert_no_match(/Limite por cliente\/dia/, response.body)
  end

  test "update step email only" do
    step = ActsAsTenant.with_tenant(accounts(:one)) { collection_steps(:friendly) }
    other = ActsAsTenant.with_tenant(accounts(:one)) do
      @steps.find { |s| s.id != step.id && s.kind_client_reminder? } || collection_steps(:firm)
    end

    patch settings_collection_ladder_path, params: {
      section: "step_email",
      step_id: step.id,
      collection_steps: {
        step.id => {
          email_enabled: "1",
          email_subject_template: "Assunto teste",
          email_body_template: "Corpo teste único"
        }
      }
    }

    assert_redirected_to edit_settings_collection_ladder_path(open_email: step.id)
    assert_equal "E-mail da etapa atualizado.", flash[:notice]

    step.reload
    other.reload
    assert_equal "Assunto teste", step.email_subject_template
    assert_equal "Corpo teste único", step.email_body_template
    assert_not_equal "Assunto teste", other.email_subject_template if other.id != step.id
  end

  test "update step whatsapp only" do
    step = ActsAsTenant.with_tenant(accounts(:one)) { collection_steps(:firm) }

    patch settings_collection_ladder_path, params: {
      section: "step_whatsapp",
      step_id: step.id,
      collection_steps: {
        step.id => {
          whatsapp_enabled: "1",
          whatsapp_template_name: "template_teste",
          whatsapp_body_template: "WA corpo teste"
        }
      }
    }

    assert_redirected_to edit_settings_collection_ladder_path(open_whatsapp: step.id)
    assert_equal "WhatsApp da etapa atualizado.", flash[:notice]

    step.reload
    assert_equal "template_teste", step.whatsapp_template_name
    assert_equal "WA corpo teste", step.whatsapp_body_template
  end

  test "does not enable email on step when smtp not configured" do
    step = ActsAsTenant.with_tenant(accounts(:one)) { collection_steps(:friendly) }
    ActionMailerDelivery.stub(:enabled?, false) do
      patch settings_collection_ladder_path, params: {
        section: "step_email",
        step_id: step.id,
        collection_steps: {
          step.id => {
            email_enabled: "1",
            email_subject_template: step.email_subject_template,
            email_body_template: step.email_body_template
          }
        }
      }
    end
    assert_redirected_to edit_settings_collection_ladder_path(open_email: step.id)
    assert_not step.reload.email_enabled?
  end

  test "step whatsapp update returns not found for internal alert" do
    internal = ActsAsTenant.with_tenant(accounts(:one)) do
      @steps.find(&:kind_internal_alert?)
    end
    skip "no internal alert step in fixtures" unless internal

    patch settings_collection_ladder_path, params: {
      section: "step_whatsapp",
      step_id: internal.id,
      collection_steps: {
        internal.id => {
          whatsapp_enabled: "0",
          whatsapp_template_name: "",
          whatsapp_body_template: ""
        }
      }
    }
    assert_response :not_found
  end

  test "unknown section returns bad request" do
    patch settings_collection_ladder_path, params: { section: "invalid" }
    assert_response :bad_request
  end

  test "preview email returns turbo frame with rendered subject" do
    step = ActsAsTenant.with_tenant(accounts(:one)) { collection_steps(:friendly) }
    client = clients(:alpha)

    post preview_email_settings_collection_ladder_path, params: {
      step_id: step.id,
      client_id: client.id,
      collection_steps: {
        step.id => {
          email_subject_template: "Preview {cliente}",
          email_body_template: "Corpo preview {cliente}"
        }
      }
    }, headers: { "Turbo-Frame" => "email_playground_preview_step_#{step.id}" }

    assert_response :success
    assert_match(/Corpo preview #{client.name}/, response.body)
    assert_match(/turbo-frame/, response.body)
    assert_match(/Enviar documentos/, response.body)
    assert_no_match(/>\s*Assunto\s*</, response.body)
    assert_no_match(/>\s*Corpo\s*</, response.body)
  end

  test "send test email redirects with notice" do
    step = ActsAsTenant.with_tenant(accounts(:one)) { collection_steps(:friendly) }
    client = clients(:alpha)

    assert_emails 1 do
      post send_test_email_settings_collection_ladder_path, params: {
        step_id: step.id,
        client_id: client.id,
        collection_steps: {
          step.id => {
            email_subject_template: "Teste {cliente}",
            email_body_template: "Corpo teste"
          }
        }
      }
    end

    assert_redirected_to edit_settings_collection_ladder_path(open_email: step.id)
    assert_match(/E-mail de teste enviado/, flash[:notice])
  end

  test "send test email fails when smtp not configured" do
    step = ActsAsTenant.with_tenant(accounts(:one)) { collection_steps(:friendly) }
    client = clients(:alpha)

    ActionMailerDelivery.stub(:enabled?, false) do
      post send_test_email_settings_collection_ladder_path, params: {
        step_id: step.id,
        client_id: client.id,
        collection_steps: {
          step.id => {
            email_subject_template: step.email_subject_template,
            email_body_template: step.email_body_template
          }
        }
      }
    end

    assert_redirected_to edit_settings_collection_ladder_path(open_email: step.id)
    assert_includes flash[:alert], "SMTP"
  end
end

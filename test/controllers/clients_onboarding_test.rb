# frozen_string_literal: true

require "test_helper"

class ClientsOnboardingTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    seed_onboarding_templates!
    @new_company_template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")
    @migration_template = accounts(:one).onboarding_templates.find_by!(kind: "migration")
  end

  test "creates client in onboarding with checklist" do
    assert_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: @new_company_template.id,
        client: {
          name: "Padaria Nova",
          email: "padaria@example.com",
          tax_id: unique_valid_test_tax_id(account: accounts(:one))
        }
      }
    end

    client = Client.find_by!(name: "Padaria Nova")
    assert client.onboarding?
    assert_equal @new_company_template.id, client.onboarding_template_id
    assert client.onboarding_checklist.present?
    assert client.onboarding_checklist.items.count.positive?
    assert_nil client.competency_checklists.find_by(period: Date.current.beginning_of_month)
    assert_redirected_to client_url(client)
  end

  test "creates client with custom template" do
    custom = accounts(:one).onboarding_templates.create!(name: "Clínica odontológica", system: false)
    custom.items.create!(name: "Alvará sanitário", position: 0)

    post clients_url, params: {
      onboarding_template_id: custom.id,
      client: {
        name: "Clínica Sorriso",
        email: "clinica@example.com",
        tax_id: unique_valid_test_tax_id(account: accounts(:one))
      }
    }

    client = Client.find_by!(name: "Clínica Sorriso")
    assert client.onboarding?
    assert_equal custom.id, client.onboarding_template_id
    assert_equal 1, client.onboarding_checklist.items.count
  end

  test "creates active client when skipping onboarding" do
    post clients_url, params: {
      onboarding_template_id: "skipped",
      client: {
        name: "Cliente Pronto",
        email: "pronto@example.com",
        tax_id: unique_valid_test_tax_id(account: accounts(:one))
      }
    }

    client = Client.find_by!(name: "Cliente Pronto")
    assert client.active?
    assert_nil client.onboarding_template_id
    assert client.competency_checklists.where(period: Date.current.beginning_of_month).exists?
  end

  test "requires onboarding template selection" do
    assert_no_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: "",
        client: {
          name: "Cliente Sem Onboarding",
          email: "sem-onboarding@example.com",
          tax_id: OnboardingTestHelper::VALID_TEST_CPF
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Selecione o tipo de onboarding", response.body
  end

  test "shows onboarding layout for onboarding client" do
    client = create_onboarding_client
    get client_url(client)
    assert_response :success
    assert_match "Em onboarding", response.body
    assert_match "Checklist de onboarding", response.body
    assert_no_match "Status do mês", response.body
  end

  test "onboarding page activate button has correct confirm modal data" do
    client = create_onboarding_client
    get client_url(client)

    assert_response :success
    assert_select "button", text: "Marcar como ativo manualmente" do |buttons|
      btn = buttons.first
      assert_equal "Marcar como ativo?", btn["data-app-confirm-modal-heading-param"]
      assert_equal client_onboarding_activation_path(client), btn["data-app-confirm-modal-url-param"]
      assert_equal client.name, btn["data-app-confirm-modal-item-label-param"]
      assert_equal "post", btn["data-app-confirm-modal-http-method-param"]
      assert_equal "Marcar como ativo", btn["data-app-confirm-modal-confirm-text-param"]
      assert_equal "primary", btn["data-app-confirm-modal-confirm-variant-param"]
    end
  end

  test "manual activation marks client active and opens period" do
    client = create_onboarding_client
    post client_onboarding_activation_url(client)

    client.reload
    assert client.active?
    assert client.competency_checklists.where(period: Date.current.beginning_of_month).exists?
  end

  test "automatic activation when all items received" do
    client = create_onboarding_client
    ActsAsTenant.with_tenant(client.account) do
      client.onboarding_checklist.items.each do |item|
        Onboarding::MarkItemReceived.call(item: item, user: users(:owner), account: client.account)
      end
      assert client.reload.active?
    end
  end

  test "creates onboarding upload invite" do
    client = create_onboarding_client
    assert_difference("UploadInvite.purpose_onboarding.count") do
      post client_onboarding_upload_invites_url(client), headers: { Accept: "application/json" }
    end
    assert_response :success
  end

  test "monthly upload blocked for onboarding client" do
    client = create_onboarding_client
    period = Date.current.beginning_of_month
    ActsAsTenant.with_tenant(client.account) do
      Periods::OpenForClient.call(client: client, period: period, account: client.account)
      invite = Clients::CreateUploadInvite.call(client: client, period: period, user: users(:owner), account: client.account)
      get public_folder_upload_url(token: invite.token)
    end
    assert_response :forbidden
    assert_match "configuração", response.body
  end

  test "public onboarding portal renders" do
    client = create_onboarding_client
    invite = ActsAsTenant.with_tenant(client.account) do
      Clients::CreateOnboardingUploadInvite.call(client: client, user: users(:owner), account: client.account)
    end
    get public_onboarding_upload_url(token: invite.token)
    assert_response :success
    assert_match "Vamos configurar sua conta?", response.body
  end

  test "migration template has more items than new company" do
    client = create_onboarding_client(onboarding_template: @migration_template, tax_id: "52998224725")
    new_company_client = create_onboarding_client(
      name: "Empresa Nova",
      onboarding_template: @new_company_template,
      tax_id: "15350946056"
    )

    assert_operator client.onboarding_checklist.items.count, :>, new_company_client.onboarding_checklist.items.count
  end
end

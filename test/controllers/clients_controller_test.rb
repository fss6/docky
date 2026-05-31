# frozen_string_literal: true

require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @client = clients(:alpha)
  end

  test "should get index" do
    get clients_url
    assert_response :success
  end

  test "index filters by unified search q" do
    get clients_url, params: { q: "Alpha" }
    assert_response :success
    assert_select "table tbody tr", count: 1
    assert_select "tr[data-clickable-row-url-value=?]", client_path(clients(:alpha))
    assert_match "Cliente Alpha", response.body
  end

  test "index filters by tax_id in unified search" do
    get clients_url, params: { q: "19.131.243/0001-97" }
    assert_response :success
    assert_select "table tbody tr", count: 1
    assert_select "tr[data-clickable-row-url-value=?]", client_path(clients(:alpha))
    assert_match "Cliente Alpha", response.body
  end

  test "index filters by status" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      @client.update!(status: :onboarding)
      clients(:beta).update!(status: :active)
    end

    get clients_url, params: { status: "onboarding" }
    assert_response :success
    assert_select "table tbody tr", count: 1
    assert_select "tr[data-clickable-row-url-value=?]", client_path(clients(:alpha))
    assert_match "Cliente Alpha", response.body
  end

  test "index shows empty state when filters match nothing" do
    get clients_url, params: { q: "zzz-inexistente" }
    assert_response :success
    assert_match "Nenhum cliente encontrado para os filtros", response.body
    assert_no_match "Nenhum cliente cadastrado ainda", response.body
  end

  test "should get new wizard" do
    seed_onboarding_templates!
    get new_client_url
    assert_response :success
    assert_select "[data-controller=?]", "client-wizard"
    assert_match I18n.t("clients.wizard.step_dados"), response.body
    assert_match I18n.t("clients.wizard.step_onboarding"), response.body
    assert_select "[data-client-wizard-target=?]", "templateCard", minimum: 1
    assert_select "input[name=?]", "client[tax_id]"
  end

  test "should create client" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")
    assert_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: {
          name: "Novo cliente Ltda",
          tax_id: "52998224725",
          email: "novo@example.com",
          phone: "",
          notes: ""
        }
      }
    end

    created = Client.find_by!(name: "Novo cliente Ltda")
    assert created.onboarding?
    assert_equal "52998224725", created.tax_id
    assert_equal template.id, created.onboarding_template_id
    assert_redirected_to client_url(created)
  end

  test "rejects create without tax_id" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")

    assert_no_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: { name: "Sem CNPJ", email: "test@example.com" }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Informe o CNPJ ou CPF", response.body
  end

  test "rejects create without email" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")

    assert_no_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: { name: "Sem E-mail", tax_id: "52998224725" }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Informe o e-mail do responsável", response.body
  end

  test "rejects create with invalid email" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")

    assert_no_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: { name: "E-mail Inválido", tax_id: "52998224725", email: "nao-e-email" }
      }
    end

    assert_response :unprocessable_entity
    assert_match "E-mail inválido", response.body
  end

  test "should create client with alphanumeric cnpj" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")
    tax_id = OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ

    assert_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: {
          name: "Empresa Alfanumérica Ltda",
          tax_id: "12.abc.345/01de-35",
          email: "alfanumerica@example.com",
          phone: "",
          notes: ""
        }
      }
    end

    created = Client.find_by!(name: "Empresa Alfanumérica Ltda")
    assert_equal tax_id, created.tax_id
    assert_redirected_to client_url(created)
  end

  test "rejects create with invalid tax_id" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")

    assert_no_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: { name: "CNPJ Inválido", tax_id: "12345678901", email: "test@example.com" }
      }
    end

    assert_response :unprocessable_entity
    assert_match "CNPJ ou CPF inválido", response.body
  end

  test "re-render wizard on step 1 when tax_id missing after onboarding selection" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "new_company")

    post clients_url, params: {
      onboarding_template_id: template.id,
      client: { name: "Cliente Sem CNPJ", email: "test@example.com" }
    }

    assert_response :unprocessable_entity
    assert_select "div[data-step='1']:not(.hidden)"
    assert_select "div[data-step='2'].hidden"
    assert_match "Informe o CNPJ ou CPF", response.body
  end

  test "re-render wizard on step 2 when onboarding not selected" do
    seed_onboarding_templates!

    post clients_url, params: {
      onboarding_template_id: "",
      client: {
        name: "Cliente Sem Onboarding",
        email: "sem-onboarding@example.com",
        tax_id: "52998224725"
      }
    }

    assert_response :unprocessable_entity
    assert_select "div[data-step='1'].hidden"
    assert_select "div[data-step='2']:not(.hidden)"
    assert_match "Selecione o tipo de onboarding", response.body
  end

  test "creates client with full wizard params" do
    seed_onboarding_templates!
    template = accounts(:one).onboarding_templates.find_by!(kind: "mei")

    assert_difference("Client.count") do
      post clients_url, params: {
        onboarding_template_id: template.id,
        client: {
          name: "MEI Wizard Test",
          tax_id: unique_valid_test_tax_id(account: accounts(:one)),
          email: "mei-wizard@example.com"
        }
      }
    end

    created = Client.find_by!(name: "MEI Wizard Test")
    assert created.onboarding?
    assert_equal template.id, created.onboarding_template_id
    assert_redirected_to client_url(created)
  end

  test "should show client" do
    seed_onboarding_templates!
    get client_url(@client, period: Date.current.strftime("%Y-%m"))
    assert_response :success
    assert_match 'aria-label="Competência"', response.body
    assert_match "Status do mês", response.body
  end

  test "should show client documents tab" do
    get client_url(@client, aba: "documentos", period: Date.current.strftime("%Y-%m"))
    assert_response :success
    assert_match "Documentos", response.body
  end

  test "should show client pastas tab" do
    get client_url(@client, aba: "pastas", period: Date.current.strftime("%Y-%m"))

    assert_response :success
    assert_match "Pastas", response.body
    assert_match folders(:one).name, response.body
    assert_select "button[data-action*='app-form-modal#open']", text: /Nova pasta/
    assert_select "#client_new_folder_modal dialog"
  end

  test "pastas tab works without open period" do
    get client_url(@client, aba: "pastas", period: Date.current.strftime("%Y-%m"))

    assert_response :success
    assert_match folders(:one).name, response.body
    assert_select "a[data-turbo-frame='folder_drawer'][href=?]",
                  client_folder_path(@client, folders(:one), period: Date.current.strftime("%Y-%m"))
  end

  test "pastas tab with folder_id renders drawer overlay" do
    folder = folders(:one)
    period_param = Date.current.strftime("%Y-%m")

    get client_url(@client, aba: "pastas", period: period_param, folder_id: folder.id)

    assert_response :success
    assert_select "#folder_drawer_shell"
    assert_select "turbo-frame#folder_drawer"
    assert_match folder.name, response.body
    assert_select "[data-folder-id='#{folder.id}']"
  end

  test "should get edit" do
    get edit_client_url(@client)
    assert_response :success
    assert_select "[data-controller=?]", "tax-id-input"
  end

  test "should update client" do
    patch client_url(@client), params: {
      client: {
        name: "Cliente Alpha Atualizado",
        tax_id: @client.tax_id,
        email: @client.email,
        phone: "",
        notes: ""
      }
    }
    assert_redirected_to client_url(@client)
    assert_equal "Cliente Alpha Atualizado", @client.reload.name
  end

  test "should archive client" do
    assert_no_difference("Client.count") do
      post archive_client_url(@client)
    end

    assert_redirected_to clients_url
    assert @client.reload.archived?
  end

  test "index includes archived client" do
    ActsAsTenant.with_tenant(@client.account) do
      Clients::Archive.call(client: @client, user: users(:owner))
    end

    get clients_url

    assert_response :success
    assert_match @client.name, response.body
    assert_match "Arquivado", response.body
  end

  test "index status active excludes archived client" do
    ActsAsTenant.with_tenant(@client.account) do
      Clients::Archive.call(client: @client, user: users(:owner))
    end

    get clients_url, params: { status: "active" }

    assert_response :success
    assert_no_match @client.name, response.body
  end
end

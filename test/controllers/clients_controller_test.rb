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
    assert_select "table tbody a", text: "Cliente Alpha"
  end

  test "index filters by tax_id in unified search" do
    get clients_url, params: { q: "11.222.333/0001-81" }
    assert_response :success
    assert_select "table tbody tr", count: 1
    assert_select "table tbody a", text: "Cliente Alpha"
  end

  test "index filters by status" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      @client.update!(status: :onboarding)
      clients(:beta).update!(status: :active)
    end

    get clients_url, params: { status: "onboarding" }
    assert_response :success
    assert_select "table tbody tr", count: 1
    assert_select "table tbody a", text: "Cliente Alpha"
  end

  test "index shows empty state when filters match nothing" do
    get clients_url, params: { q: "zzz-inexistente" }
    assert_response :success
    assert_match "Nenhum cliente encontrado para os filtros", response.body
    assert_no_match "Nenhum cliente cadastrado ainda", response.body
  end

  test "should get new" do
    get new_client_url
    assert_response :success
  end

  test "should create client" do
    seed_onboarding_templates!
    assert_difference("Client.count") do
      post clients_url, params: {
        onboarding_kind: "new_client",
        client: {
          name: "Novo cliente Ltda",
          tax_id: "99888777000166",
          email: "novo@example.com",
          phone: "",
          notes: ""
        }
      }
    end

    created = Client.find_by!(name: "Novo cliente Ltda")
    assert created.onboarding?
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

  test "should get edit" do
    get edit_client_url(@client)
    assert_response :success
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
end

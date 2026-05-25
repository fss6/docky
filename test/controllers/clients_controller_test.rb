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

  test "should get new" do
    get new_client_url
    assert_response :success
  end

  test "should create client" do
    assert_difference("Client.count") do
      post clients_url, params: {
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
    assert_redirected_to client_url(created)
  end

  test "should show client" do
    get client_url(@client)
    assert_response :success
    assert_match "Status do mês", response.body
  end

  test "should show client documents tab" do
    get client_url(@client, aba: "documentos")
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

  test "should destroy client" do
    assert_difference("Client.count", -1) do
      delete client_url(@client)
    end

    assert_redirected_to clients_url
  end
end

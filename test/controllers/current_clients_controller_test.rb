# frozen_string_literal: true

require "test_helper"

class CurrentClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @client = clients(:alpha)
  end

  test "should set current client in session" do
    patch current_client_url, params: { client_id: @client.id }
    assert_redirected_to dashboard_path
    assert_equal @client.id, session[:current_client_id]
  end

  test "should clear current client when client_id blank" do
    patch current_client_url, params: { client_id: @client.id }
    patch current_client_url, params: { client_id: "" }
    assert_redirected_to dashboard_path
    assert_nil session[:current_client_id]
  end
end

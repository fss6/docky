# frozen_string_literal: true

require "test_helper"

class LegacyFoldersRedirectControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @client = clients(:alpha)
    @visible_folder = folders(:one)
    @period_param = Date.current.strftime("%Y-%m")
  end

  test "index redirects to clients" do
    get folders_url

    assert_redirected_to clients_path
  end

  test "new redirects to client pastas when current client is set" do
    patch current_client_url, params: { client_id: @client.id }

    get new_folder_url

    assert_redirected_to client_path(@client, aba: "pastas", period: @period_param)
  end

  test "new redirects to clients without current client" do
    patch current_client_url, params: { client_id: "" }

    get new_folder_url

    assert_redirected_to clients_path
  end

  test "show redirects visible folder to client pastas drawer" do
    get folder_url(@visible_folder)

    assert_redirected_to client_path(
      @client,
      aba: "pastas",
      period: @period_param,
      folder_id: @visible_folder.id
    )
  end

  test "edit redirects visible folder to client pastas drawer" do
    get edit_folder_url(@visible_folder)

    assert_redirected_to client_path(
      @client,
      aba: "pastas",
      period: @period_param,
      folder_id: @visible_folder.id
    )
  end

  test "show redirects monthly shim to folder documents" do
    shim = nil
    ActsAsTenant.with_tenant(accounts(:one)) do
      shim = Folder.create!(
        account: accounts(:one),
        client: @client,
        name: @period_param,
        visible: false
      )
    end

    get folder_url(shim)

    assert_redirected_to folder_documents_path(shim)
  end
end

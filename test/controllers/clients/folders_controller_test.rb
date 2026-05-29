# frozen_string_literal: true

require "test_helper"

module Clients
  class FoldersControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:owner)
      @client = clients(:alpha)
      @folder = folders(:one)
      @period_param = Date.current.strftime("%Y-%m")
    end

    test "index redirects to client pastas tab" do
      get client_folders_url(@client)

      assert_redirected_to client_path(@client, aba: "pastas", period: @period_param)
    end

    test "should get new" do
      get new_client_folder_url(@client)

      assert_response :success
    end

    test "should create folder" do
      assert_difference("Folder.count") do
        post client_folders_url(@client),
             params: { folder: { name: "Financeiro 2026" }, period: @period_param }
      end

      created = Folder.order(:id).last
      assert_equal @client.id, created.client_id
      assert created.visible?
      assert_redirected_to client_path(@client, aba: "pastas", period: @period_param)
    end

    test "should create folder via turbo stream" do
      assert_difference("Folder.count") do
        post client_folders_url(@client),
             params: { folder: { name: "Fiscal 2026" }, period: @period_param },
             as: :turbo_stream
      end

      assert_response :success
      assert_match "turbo-stream", response.media_type
      assert_match "client_pastas_frame", response.body
      assert_match "Fiscal 2026", response.body
    end

    test "should redirect html show to client pastas with folder_id" do
      get client_folder_url(@client, @folder, period: @period_param)

      assert_redirected_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id)
    end

    test "should show folder in drawer frame without public upload section" do
      get client_folder_url(@client, @folder, period: @period_param),
          headers: { "Turbo-Frame" => "folder_drawer" }

      assert_response :success
      assert_select "turbo-frame#folder_drawer", count: 1
      assert_match @folder.name, response.body
      assert_no_match "Link público", response.body
      assert_no_match "Compartilhar upload", response.body
      assert_match "Anexar arquivo", response.body
    end

    test "drawer_empty returns empty folder_drawer frame" do
      get drawer_empty_client_folders_url(@client, period: @period_param),
          headers: { "Turbo-Frame" => "folder_drawer" }

      assert_response :success
      assert_select "turbo-frame#folder_drawer", count: 1
      assert_select "turbo-frame#folder_drawer:empty", count: 1
    end

    test "destroy empty folder via turbo stream clears drawer and refreshes grid" do
      empty_folder = nil
      ActsAsTenant.with_tenant(accounts(:one)) do
        empty_folder = Folder.create!(
          account: accounts(:one),
          client: @client,
          name: "Pasta vazia stream",
          visible: true
        )
      end

      assert_difference("Folder.count", -1) do
        delete client_folder_url(@client, empty_folder),
               params: { period: @period_param },
               as: :turbo_stream
      end

      assert_response :success
      assert_match "turbo-stream", response.media_type
      assert_match 'target="folder_drawer"', response.body
      assert_match 'target="client_pastas_frame"', response.body
      assert_no_match 'turbo-stream action="redirect"', response.body
    end

    test "should get edit" do
      get edit_client_folder_url(@client, @folder)

      assert_response :success
    end

    test "should update folder via turbo stream" do
      patch client_folder_url(@client, @folder),
            params: { folder: { name: "Pasta renomeada" }, period: @period_param },
            as: :turbo_stream

      assert_response :success
      assert_match 'target="client_pastas_frame"', response.body
      assert_match "Pasta renomeada", response.body
      assert_equal "Pasta renomeada", @folder.reload.name
    end

    test "should destroy empty folder" do
      empty_folder = nil
      ActsAsTenant.with_tenant(accounts(:one)) do
        empty_folder = Folder.create!(
          account: accounts(:one),
          client: @client,
          name: "Pasta vazia",
          visible: true
        )
      end

      assert_difference("Folder.count", -1) do
        delete client_folder_url(@client, empty_folder), params: { period: @period_param }
      end

      assert_redirected_to client_path(@client, aba: "pastas", period: @period_param)
    end

    test "should not destroy folder with documents" do
      assert documents(:one).folder_id == @folder.id

      assert_no_difference("Folder.count") do
        delete client_folder_url(@client, @folder),
               params: { period: @period_param },
               as: :turbo_stream
      end

      assert_response :unprocessable_entity
      assert_match I18n.t("folders.destroy_blocked_with_documents"), response.body
    end

    test "cannot access folder belonging to another client" do
      other_client = clients(:beta)

      get client_folder_url(other_client, @folder)

      assert_response :not_found
    end

    test "cannot show invisible folder shim" do
      ActsAsTenant.with_tenant(accounts(:one)) do
        shim = Folder.create!(
          account: accounts(:one),
          client: @client,
          name: @period_param,
          visible: false
        )

        get client_folder_url(@client, shim)

        assert_response :not_found
      end
    end
  end
end

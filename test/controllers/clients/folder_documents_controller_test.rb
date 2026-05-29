# frozen_string_literal: true

require "test_helper"

module Clients
  class FolderDocumentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:owner)
      @client = clients(:alpha)
      @folder = folders(:one)
      @period_param = Date.current.strftime("%Y-%m")
    end

    test "should create document via turbo stream" do
      ActsAsTenant.with_tenant(accounts(:one)) do
        @folder.documents.destroy_all
      end

      file = fixture_file_upload("sample.txt", "text/plain")

      assert_difference("Document.count") do
        post client_folder_documents_url(@client, @folder),
             params: { document: { file: file }, period: @period_param },
             as: :turbo_stream
      end

      assert_response :success
      assert_match "turbo-stream", response.media_type
      assert_match "folder_documents_frame", response.body
      assert_match 'target="client_pastas_frame"', response.body
      assert_match "sample.txt", response.body
    end

    test "should destroy document via turbo stream" do
      document = documents(:one)
      assert_equal @folder.id, document.folder_id

      assert_difference("Document.count", -1) do
        delete client_folder_document_url(@client, @folder, document),
               params: { period: @period_param },
               as: :turbo_stream
      end

      assert_response :success
      assert_match "turbo-stream", response.media_type
      assert_match "folder_documents_frame", response.body
      assert_match 'target="client_pastas_frame"', response.body
    end
  end
end

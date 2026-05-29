# frozen_string_literal: true

require "test_helper"

module Clients
  class DocumentsControllerTest < ActionDispatch::IntegrationTest
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste", price: 0)
      @account = Account.create!(name: "Conta Teste", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Owner Teste",
        email: "owner-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente Teste")
        month = Date.current.beginning_of_month
        @period = month.strftime("%Y-%m")
        Period.create!(account: @account, client: @client, period: month)
        Folder.create!(account: @account, client: @client, name: @period, visible: false)
      end
      sign_in @user
    end

    test "should create internal document upload" do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files/minimal.pdf"),
        "application/pdf"
      )

      assert_difference("Document.count", 1) do
        assert_enqueued_jobs 1, only: DocumentOcrJob do
          post client_documents_path(@client, period: @period),
               params: { document: { file: file } },
               headers: { Accept: "text/vnd.turbo-stream.html" }
        end
      end

      assert_response :success
      document = Document.order(:created_at).last
      assert_equal @client.id, document.client_id
      assert_equal Date.current.beginning_of_month, document.collection_period
      assert_equal "pending", document.status
      assert_equal "internal_upload", document.metadata["upload_source"]
      assert document.file.attached?
      assert_match "client_documents_frame", response.body
      assert_match "Documento adicionado com sucesso", response.body
    end

    test "rejects unsupported internal document upload" do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files/sample.txt"),
        "text/plain"
      )

      assert_no_difference("Document.count") do
        post client_documents_path(@client, period: @period),
             params: { document: { file: file } },
             headers: { Accept: "text/vnd.turbo-stream.html" }
      end

      assert_response :unprocessable_entity
      assert_match "Formato não aceito", response.body
    end

    test "should destroy document via turbo stream" do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files/minimal.pdf"),
        "application/pdf"
      )

      post client_documents_path(@client, period: @period),
           params: { document: { file: file } },
           headers: { Accept: "text/vnd.turbo-stream.html" }

      document = Document.order(:created_at).last

      assert_difference("Document.count", -1) do
        delete client_document_path(@client, document, period: @period),
               headers: { Accept: "text/vnd.turbo-stream.html" }
      end

      assert_response :success
      assert_match "client_documents_frame", response.body
      assert_match "Documento excluído com sucesso", response.body
    end
  end
end

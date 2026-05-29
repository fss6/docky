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

    test "reuses processing when uploading duplicate file content" do
      pdf_path = Rails.root.join("test/fixtures/files/minimal.pdf")
      content_hash = Digest::SHA256.file(pdf_path).hexdigest
      source = nil

      ActsAsTenant.with_tenant(@account) do
        folder = Folder.find_by!(client: @client, name: @period)
        source = Document.create!(
          account: @account,
          user: @user,
          folder: folder,
          client: @client,
          status: :processed,
          content: "cached ocr",
          content_sha256: content_hash,
          metadata: { "mistral_ocr" => { "model" => "mistral-ocr-latest" } }
        )
        source.file.attach(
          io: File.open(pdf_path),
          filename: "minimal.pdf",
          content_type: "application/pdf"
        )
        EmbeddingRecord.create!(
          account: @account,
          recordable: source,
          document_id: source.id,
          content: "cached chunk",
          metadata: { "page" => 0, "source" => "ocr" }
        )
      end

      file = Rack::Test::UploadedFile.new(pdf_path, "application/pdf")

      assert_difference("Document.count", 1) do
        assert_no_enqueued_jobs(only: DocumentOcrJob) do
          post client_documents_path(@client, period: @period),
               params: { document: { file: file } },
               headers: { Accept: "text/vnd.turbo-stream.html" }
        end
      end

      document = Document.order(:created_at).last
      assert_equal "processed", document.status
      assert_equal content_hash, document.content_sha256
      assert_equal source.id, document.metadata["processing_copied_from_document_id"]
      assert_equal 1, document.embedding_records.count
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

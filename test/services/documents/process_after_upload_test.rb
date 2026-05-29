# frozen_string_literal: true

require "test_helper"

module Documents
  class ProcessAfterUploadTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @account = accounts(:one)
      @user = users(:owner)
      @folder = folders(:one)
      @pdf_path = Rails.root.join("test/fixtures/files/minimal.pdf")
      @uploaded = Rack::Test::UploadedFile.new(@pdf_path, "application/pdf")
      @content_hash = Digest::SHA256.file(@pdf_path).hexdigest
    end

    test "enqueues OCR job on cache miss" do
      ActsAsTenant.with_tenant(@account) do
        document = build_document

        assert_enqueued_with(job: DocumentOcrJob, args: [ document.id ]) do
          ProcessAfterUpload.call(document: document, file_io: @uploaded)
        end

        assert_equal @content_hash, document.reload.content_sha256
        assert_equal "pending", document.status
      end
    end

    test "clones processing on cache hit without enqueuing OCR" do
      ActsAsTenant.with_tenant(@account) do
        source = build_processed_source

        document = build_document
        assert_no_enqueued_jobs(only: DocumentOcrJob) do
          ProcessAfterUpload.call(document: document, file_io: @uploaded)
        end

        document.reload
        assert_equal "processed", document.status
        assert_equal source.id, document.metadata["processing_copied_from_document_id"]
        assert_equal 1, document.embedding_records.count
      end
    end

    test "reprocesses when only failed document exists with same hash" do
      ActsAsTenant.with_tenant(@account) do
        Document.create!(
          account: @account,
          user: @user,
          folder: @folder,
          status: :failed,
          content_sha256: @content_hash,
          metadata: { "ocr_error" => { "message" => "boom" } }
        )

        document = build_document
        assert_enqueued_with(job: DocumentOcrJob, args: [ document.id ]) do
          ProcessAfterUpload.call(document: document, file_io: @uploaded)
        end
      end
    end

    test "does nothing when file is not attached" do
      ActsAsTenant.with_tenant(@account) do
        document = Document.new(
          account: @account,
          user: @user,
          folder: @folder,
          status: :pending
        )
        document.save!

        assert_no_enqueued_jobs do
          ProcessAfterUpload.call(document: document)
        end
      end
    end

    private

    def build_document
      document = Document.create!(
        account: @account,
        user: @user,
        folder: @folder,
        status: :pending
      )
      document.file.attach(
        io: File.open(@pdf_path),
        filename: "minimal.pdf",
        content_type: "application/pdf"
      )
      document
    end

    def build_processed_source
      source = Document.create!(
        account: @account,
        user: @user,
        folder: @folder,
        status: :processed,
        content: "cached",
        content_sha256: @content_hash,
        metadata: { "mistral_ocr" => { "model" => "mistral-ocr-latest" } }
      )
      source.file.attach(
        io: File.open(@pdf_path),
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
      source
    end
  end
end

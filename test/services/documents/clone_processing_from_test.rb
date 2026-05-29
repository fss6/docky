# frozen_string_literal: true

require "test_helper"

module Documents
  class CloneProcessingFromTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @user = users(:owner)
      @folder = folders(:one)
      @pdf_path = Rails.root.join("test/fixtures/files/minimal.pdf")
      @content_hash = Digest::SHA256.file(@pdf_path).hexdigest
      @vector = Array.new(1536, 0.1)

      ActsAsTenant.with_tenant(@account) do
        @source = Document.create!(
          account: @account,
          user: @user,
          folder: @folder,
          status: :processed,
          content: "Texto OCR",
          summary: "Resumo",
          tags: %w[contrato fiscal],
          content_sha256: @content_hash,
          metadata: {
            "mistral_ocr" => { "model" => "mistral-ocr-latest", "extracted_at" => Time.current.iso8601 }
          }
        )
        @source.file.attach(
          io: File.open(@pdf_path),
          filename: "minimal.pdf",
          content_type: "application/pdf"
        )
        EmbeddingRecord.create!(
          account: @account,
          recordable: @source,
          document_id: @source.id,
          content: "chunk one",
          embedding: @vector,
          metadata: { "page" => 0, "chunk_index" => 0, "source" => "ocr" }
        )

        @target = Document.create!(
          account: @account,
          user: @user,
          folder: @folder,
          status: :pending,
          metadata: { "upload_source" => "internal_upload" }
        )
        @target.file.attach(
          io: File.open(@pdf_path),
          filename: "minimal-copy.pdf",
          content_type: "application/pdf"
        )
      end
    end

    test "copies processing artifacts from source to target" do
      ActsAsTenant.with_tenant(@account) do
        CloneProcessingFrom.call(source: @source, target: @target)
        @target.reload

        assert_equal "processed", @target.status
        assert_equal "Texto OCR", @target.content
        assert_equal "Resumo", @target.summary
        assert_equal %w[contrato fiscal], @target.tags
        assert_equal @source.id, @target.metadata["processing_copied_from_document_id"]
        assert @target.metadata["processing_copied_at"].present?
        assert_equal "mistral-ocr-latest", @target.metadata.dig("mistral_ocr", "model")

        records = @target.embedding_records.order(:id)
        assert_equal 1, records.size
        assert_equal "chunk one", records.first.content
        assert_equal @vector, records.first.embedding
        assert_equal @target.id, records.first.document_id
        assert_equal @target, records.first.recordable
      end
    end
  end
end

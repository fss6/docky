# frozen_string_literal: true

require "test_helper"

module Documents
  class AllowedUploadTest < ActiveSupport::TestCase
    test "accepts allowed extensions with matching content types" do
      {
        "report.pdf" => "application/pdf",
        "nfe.xml" => "application/xml",
        "photo.jpg" => "image/jpeg",
        "photo.jpeg" => "image/jpeg",
        "scan.png" => "image/png",
        "contract.doc" => "application/msword",
        "contract.docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "extrato.xls" => "application/vnd.ms-excel",
        "extrato.xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      }.each do |filename, content_type|
        file = uploaded_file(filename, content_type)

        assert AllowedUpload.allowed?(file), "expected #{filename} to be allowed"
        assert AllowedUpload.extension_allowed?(filename), "expected #{filename} extension to be allowed"
      end
    end

    test "accepts generic octet-stream for allowed extensions" do
      file = uploaded_file("extrato.xlsx", "application/octet-stream")

      assert AllowedUpload.allowed?(file)
    end

    test "rejects disallowed extensions" do
      file = uploaded_file("notes.txt", "text/plain")

      assert_not AllowedUpload.allowed?(file)
    end

    test "rejects zip even with generic content type" do
      file = uploaded_file("lote.zip", "application/octet-stream")

      assert_not AllowedUpload.allowed?(file)
    end

    test "rejects spoofed pdf extension with executable content type" do
      file = uploaded_file("malware.pdf", "application/x-msdownload")

      assert_not AllowedUpload.allowed?(file)
    end

    test "accept_attribute includes extensions and mime types" do
      attribute = AllowedUpload.accept_attribute

      assert_includes attribute, ".pdf"
      assert_includes attribute, "application/pdf"
      assert_includes attribute, ".xlsx"
    end

    test "client facing label and validation message avoid competencia jargon" do
      assert_includes AllowedUpload.client_facing_label, "Word"
      assert_includes AllowedUpload.validation_error_message, "Formato não aceito"
      assert_not_includes AllowedUpload.validation_error_message.downcase, "competência"
    end

    private

    def uploaded_file(filename, content_type)
      Rack::Test::UploadedFile.new(StringIO.new("payload"), content_type, original_filename: filename)
    end
  end
end

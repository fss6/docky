# frozen_string_literal: true

require "test_helper"

module Documents
  class ContentFingerprintTest < ActiveSupport::TestCase
    test "sha256_hex computes digest from io" do
      io = StringIO.new("hello world")
      expected = Digest::SHA256.hexdigest("hello world")

      assert_equal expected, ContentFingerprint.sha256_hex(io)
    end

    test "from_upload reads uploaded file and rewinds io" do
      path = Rails.root.join("test/fixtures/files/minimal.pdf")
      uploaded = Rack::Test::UploadedFile.new(path, "application/pdf")
      expected = Digest::SHA256.file(path).hexdigest

      assert_equal expected, ContentFingerprint.from_upload(uploaded)
      assert_equal 0, uploaded.tempfile.pos
    end

    test "from_blob reads attached blob" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/minimal.pdf")),
        filename: "minimal.pdf",
        content_type: "application/pdf"
      )
      expected = Digest::SHA256.file(Rails.root.join("test/fixtures/files/minimal.pdf")).hexdigest

      assert_equal expected, ContentFingerprint.from_blob(blob)
    end
  end
end

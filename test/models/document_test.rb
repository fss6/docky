# frozen_string_literal: true

require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @user = users(:owner)
    @folder = folders(:one)

    ActsAsTenant.with_tenant(@account) do
      @document = Document.new(
        account: @account,
        user: @user,
        folder: @folder,
        status: :pending
      )
    end
  end

  test "allows supported file types" do
    ActsAsTenant.with_tenant(@account) do
      @document.file.attach(
        io: File.open(Rails.root.join("test/fixtures/files/minimal.pdf")),
        filename: "minimal.pdf",
        content_type: "application/pdf"
      )

      assert @document.valid?
    end
  end

  test "rejects unsupported file types" do
    ActsAsTenant.with_tenant(@account) do
      @document.file.attach(
        io: File.open(Rails.root.join("test/fixtures/files/sample.txt")),
        filename: "sample.txt",
        content_type: "text/plain"
      )

      assert_not @document.valid?
      assert_includes @document.errors[:file], Documents::AllowedUpload.validation_error_message
    end
  end
end

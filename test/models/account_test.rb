# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "accepts valid contact email" do
    account = accounts(:one)
    account.contact_email = "contato@example.com"

    assert account.valid?, account.errors.full_messages.to_sentence
  end

  test "rejects invalid contact email" do
    account = accounts(:one)
    account.contact_email = "invalid-email"

    assert_not account.valid?
    assert account.errors[:contact_email].present?
  end

  test "accepts blank contact email" do
    account = accounts(:one)
    account.contact_email = ""

    assert account.valid?, account.errors.full_messages.to_sentence
  end

  test "accepts valid logo" do
    account = accounts(:one)
    file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/avatar.png"), "image/png")
    account.logo = file

    assert account.valid?, account.errors.full_messages.to_sentence
  end

  test "rejects invalid logo content type" do
    account = accounts(:one)
    file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/minimal.pdf"), "application/pdf")
    account.logo = file

    assert_not account.valid?
    assert_includes account.errors[:logo], Accounts::LogoUpload.validation_error_message
  end

  test "rejects logo larger than 2 MB" do
    account = accounts(:one)
    large_io = StringIO.new("x" * (2.megabytes + 1))
    file = Rack::Test::UploadedFile.new(large_io, "image/png", original_filename: "large.png")
    account.logo = file

    assert_not account.valid?
    assert_includes account.errors[:logo], Accounts::LogoUpload.validation_error_message
  end

  test "remove_logo purges attachment" do
    account = accounts(:one)
    account.logo.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "logo.png",
      content_type: "image/png"
    )

    account.remove_logo = "1"
    account.valid?

    assert_not account.logo.attached?
  end

  test "current_subscription returns active subscription" do
    account = accounts(:one)
    subscription = subscriptions(:one)

    assert_equal subscription, account.current_subscription
  end

  test "current_subscription returns nil when no active subscription" do
    account = accounts(:two)
    account.subscriptions.update_all(status: :canceled)

    assert_nil account.current_subscription
  end
end

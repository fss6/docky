# frozen_string_literal: true

require "test_helper"

class AccountProfilesHelperTest < ActionView::TestCase
  include AccountProfilesHelper

  setup do
    @account = accounts(:one)
  end

  test "client_facing_account_logo uses dokivo fallback when logo missing" do
    html = client_facing_account_logo(@account)

    assert_includes html, "/brand/logo.svg"
    assert_includes html, 'alt="Dokivo"'
    assert_includes html, "client-brand-logo"
  end

  test "client_facing_account_logo uses attached logo" do
    @account.logo.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "logo.png",
      content_type: "image/png"
    )

    html = client_facing_account_logo(@account.reload)

    assert_includes html, "/rails/active_storage/"
    assert_includes html, %(alt="#{@account.name}")
    assert_not_includes html, "/brand/logo.svg"
  end
end

# frozen_string_literal: true

require "test_helper"

class ClientsHelperTest < ActiveSupport::TestCase
  include ClientsHelper
  include Rails.application.routes.url_helpers

  def setup_fixtures
  end

  def teardown_fixtures
  end

  def setup
    @request = ActionDispatch::TestRequest.create
  end

  def request
    @request
  end

  test "public_upload_host strips portal prefix from request host" do
    @request.host = "portal.example.com"
    assert_equal "example.com", public_upload_host
  end

  test "public_upload_host uses PUBLIC_APP_HOST when set" do
    ENV["PUBLIC_APP_HOST"] = "app.dokivo.com.br"
    assert_equal "app.dokivo.com.br", public_upload_host
  ensure
    ENV.delete("PUBLIC_APP_HOST")
  end

  test "client_public_upload_url uses host without portal" do
    @request.host = "portal.localhost"
    @request.env["HTTPS"] = "off"
    url = client_public_upload_url("test-token")
    assert_includes url, "localhost"
    assert_not_includes url, "portal."
    assert_includes url, "/portal/"
    assert_not_includes url, "/public/folders/"
    assert_includes url, "test-token"
  end
end

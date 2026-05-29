# frozen_string_literal: true

require "test_helper"

class TimelinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
  end

  test "redirects timeline to clients index" do
    get timeline_url

    assert_redirected_to clients_path
  end

  test "redirects timeline period to clients index" do
    get timeline_period_url(Date.current.strftime("%Y-%m"))

    assert_redirected_to clients_path
  end
end

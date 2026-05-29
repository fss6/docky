# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
  end

  test "index loads successfully" do
    get dashboard_url

    assert_response :success
    assert_includes response.body, "Dashboard"
  end
end

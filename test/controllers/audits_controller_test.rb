# frozen_string_literal: true

require "test_helper"

class AuditsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
  end

  test "index loads successfully" do
    get audits_path

    assert_response :success
    assert_includes response.body, "Auditoria"
  end
end

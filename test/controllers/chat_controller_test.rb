# frozen_string_literal: true

require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
  end

  test "index redirects to conversations and page loads" do
    get chat_path

    assert_redirected_to account_conversations_path(accounts(:one))
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Assistente de IA"
  end
end

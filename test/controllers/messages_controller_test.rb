# frozen_string_literal: true

require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @conversation = conversations(:one)
    @document = documents(:one)
  end

  test "create turbo stream keeps focus document in the refreshed form" do
    post account_conversation_messages_url(@account, @conversation),
         params: { message: { content: "Analise este documento", focus_document_id: @document.id } },
         headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal @document.id, @conversation.messages.where(role: "user").order(:id).last.focus_document_id
    assert_includes response.body, 'action="remove" target="chat-empty-state"'
    assert_includes response.body, %(name="message[focus_document_id]")
    assert_includes response.body, %(value="#{@document.id}")
    assert_includes response.body, "thinking-dot"
    assert_includes response.body, I18n.t("messages.chat.thinking")
    assert_not_includes response.body, "**"
  end
end

# frozen_string_literal: true

require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @conversation = conversations(:one)
  end

  test "index shows sidebar without ver todas link or duplicate conversation list" do
    get account_conversations_url(@account)

    assert_response :success
    assert_includes response.body, "Assistente de IA"
    assert_includes response.body, "Selecione uma conversa"
    assert_not_includes response.body, "Ver todas"
    assert_not_includes response.body, "divide-y divide-zinc-100"
  end

  test "show renders empty state for conversation without messages" do
    conversation = @account.conversations.create!(user: users(:owner), title: "Nova conversa")

    get account_conversation_url(@account, conversation)

    assert_response :success
    assert_includes response.body, "Comece uma nova conversa"
    assert_includes response.body, "Resuma os principais pontos deste documento."
  end

  test "show with messages uses centered thread without main header" do
    @conversation.messages.create!(
      role: "assistant",
      content: "Resposta com **markdown**.",
      streaming: false
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, "max-w-3xl"
    assert_includes response.body, "chat-assistant-content"
    assert_includes response.body, I18n.t("messages.chat.assistant_name")
    assert_includes response.body, "<strong>markdown</strong>"
    assert_not_includes response.body, "**markdown**"
    assert_not_includes response.body, "Assistente de IA"
    assert_not_includes response.body, "arquivo indexado"
  end

  test "show renders assistant markdown with bold labels" do
    @conversation.messages.create!(
      role: "assistant",
      content: "**Período:** abril de 2026.",
      streaming: false
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, "<strong>Período:</strong>"
    assert_not_includes response.body, "**Período:**"
  end

  test "show renders thinking indicator for streaming assistant message" do
    @conversation.messages.create!(
      role: "assistant",
      content: "",
      streaming: true
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, "thinking-dot"
    assert_includes response.body, I18n.t("messages.chat.thinking")
    assert_not_includes response.body, "**"
  end

  test "show renders source chips on assistant message" do
    document = documents(:one)
    @conversation.messages.create!(
      role: "assistant",
      content: "Resposta com fontes.",
      streaming: false,
      sources: [
        { "file" => "contrato.pdf", "page" => 2, "document_id" => document.id, "chunk_id" => 1 }
      ]
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, "contrato.pdf"
    assert_includes response.body, "p. 2"
    assert_includes response.body, document_path(document)
    assert_not_includes response.body, "Contexto"
  end

  test "show renders retrieving thinking with chunks secondary" do
    @conversation.messages.create!(
      role: "assistant",
      content: "",
      streaming: true,
      metadata: {
        "loading" => "assistant",
        "thinking" => {
          "phase" => "retrieving",
          "intent" => "document",
          "chunks_count" => 3
        }
      }
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, I18n.t("messages.chat.thinking_status.retrieving.document.primary")
    assert_includes response.body, I18n.t("messages.chat.thinking_status.chunks_found", count: 3)
    assert_includes response.body, I18n.t("messages.chat.thinking_status.brand")
  end

  test "show renders structured components from metadata" do
    @conversation.messages.create!(
      role: "assistant",
      content: "Resumo energia",
      metadata: {
        schema_version: 1,
        components: [
          { type: "rich_text", data: { content: "**Total:** 734 kWh" } },
          {
            type: "table",
            data: { title: "Energia", headers: %w[Mês kWh], rows: [["Novembro 2025", "714"]] }
          }
        ]
      },
      streaming: false
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, "<strong>Total:</strong>"
    assert_match %r{<table\b}, response.body
    assert_includes response.body, "Novembro 2025"
    assert_includes response.body, "Energia"
  end

  test "show renders structured tables from legacy metadata" do
    @conversation.messages.create!(
      role: "assistant",
      content: "Resumo dos últimos meses:",
      metadata: {
        tables: [
          {
            title: "Energia",
            columns: %w[Mês kWh],
            rows: [["Novembro 2025", "714"]]
          }
        ]
      },
      streaming: false
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_match %r{<table\b}, response.body
    assert_includes response.body, "Novembro 2025"
    assert_includes response.body, "Energia"
  end

  test "show keeps focused document from latest user message" do
    document = documents(:one)
    file_fixture("avatar.png").open do |file|
      document.file.attach(io: file, filename: "avatar.png", content_type: "image/png")
    end
    @conversation.messages.create!(
      role: "user",
      content: "Resuma este arquivo",
      metadata: { "focus_document_id" => document.id },
      streaming: false
    )

    get account_conversation_url(@account, @conversation)

    assert_response :success
    assert_includes response.body, "Documento em foco"
    assert_includes response.body, %(name="message[focus_document_id]")
    assert_includes response.body, %(value="#{document.id}")
  end

  test "destroy removes conversation and redirects" do
    assert_difference("Conversation.count", -1) do
      delete account_conversation_url(@account, @conversation)
    end

    assert_redirected_to account_conversations_url(@account)
  end
end

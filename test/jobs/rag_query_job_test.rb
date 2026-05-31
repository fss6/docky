# frozen_string_literal: true

require "test_helper"

class RagQueryJobTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @conversation = conversations(:one)
    @conversation.messages.destroy_all
    @vector = Array.new(1536, 0.1)

    @document = documents(:one)
    @document.update!(account: @account, status: :processed)
    EmbeddingRecord.where(account: @account, recordable_type: "Document").delete_all
    EmbeddingRecord.create!(
      account: @account,
      recordable: @document,
      document_id: @document.id,
      content: "Faturamento microgeração abril 2026",
      embedding: @vector,
      metadata: { "page" => 0, "chunk_index" => 0, "source" => "ocr" }
    )

    @user_message = @conversation.messages.create!(
      role: "user",
      content: "preciso ver os dados em formato de tabela",
      streaming: false
    )
    @ai_message = @conversation.messages.create!(
      role: "assistant",
      content: "",
      streaming: true
    )

    @chunk = EmbeddingRecord.where(account: @account, recordable_type: "Document").first
    @wiki_result = { wiki_chunks: [], doc_chunks: [@chunk] }
  end

  def structured_result(summary:, tables: [])
    components = []
    components << { "type" => "rich_text", "data" => { "content" => summary } } if summary.present?
    tables.each do |table|
      components << {
        "type" => "table",
        "data" => {
          "title" => table["title"],
          "headers" => table["columns"] || table["headers"],
          "rows" => table["rows"]
        }
      }
    end

    Messages::StructuredAssistantReply::Result.new(
      summary: summary,
      components: components,
      schema_version: 1
    )
  end

  test "tabular request stores components in metadata and does not stream" do
    result = structured_result(
      summary: "Resumo:",
      tables: [{ "title" => "Dados", "columns" => %w[Campo Valor], "rows" => [["Período", "abril 2026"]] }]
    )

    wiki_service = mock("wiki_query")
    wiki_service.stubs(:call).returns(@wiki_result)
    Wiki::QueryService.stubs(:new).returns(wiki_service)

    Messages::StructuredAssistantReply.stub(:call, result) do
      LlmService.stub(:stream, ->(*) { raise "stream should not be called" }) do
        RagQueryJob.perform_now(@ai_message.id)
      end
    end

    @ai_message.reload
    assert_not @ai_message.streaming?
    assert_includes @ai_message.content, "Resumo:"
    assert_equal 1, @ai_message.structured_tables.size
    assert_equal %w[Campo Valor], @ai_message.structured_tables.first["columns"]
    assert @ai_message.structured_components.any? { |c| c["type"] == "table" }
    assert_equal 1, @ai_message.metadata["schema_version"]
    assert @ai_message.sources.present?
  end

  test "document reply uses structured assistant reply without stream" do
    @user_message.update!(content: "Resumo do contrato")
    ai_message = @conversation.messages.create!(role: "assistant", content: "", streaming: true)

    result = Messages::StructuredAssistantReply::Result.new(
      summary: "",
      components: [{ "type" => "rich_text", "data" => { "content" => "Resposta **em** negrito" } }],
      schema_version: 1
    )

    wiki_service = mock("wiki_query")
    wiki_service.stubs(:call).returns(@wiki_result)
    Wiki::QueryService.stubs(:new).returns(wiki_service)

    Messages::StructuredAssistantReply.stub(:call, result) do
      LlmService.stub(:stream, ->(*) { raise "stream should not be called" }) do
        RagQueryJob.perform_now(ai_message.id)
      end
    end

    ai_message.reload
    assert_not ai_message.streaming?
    assert_includes ai_message.content, "negrito"
    assert ai_message.structured_response?
    assert_empty ai_message.structured_tables
  end

  test "gere after tabular error uses structured reply not stream" do
    @user_message.update!(content: "em formato de tabela")
    @conversation.messages.create!(
      role: "assistant",
      content: RagQueryJob::TABULAR_ERROR_TEXT,
      streaming: false
    )
    @conversation.messages.create!(role: "user", content: "gere", streaming: false)
    ai_message = @conversation.messages.create!(role: "assistant", content: "", streaming: true)

    result = structured_result(
      summary: "Dados:",
      tables: [{ "title" => "Energia", "columns" => %w[Campo Valor], "rows" => [["kWh", "734"]] }]
    )

    wiki_service = mock("wiki_query")
    wiki_service.stubs(:call).returns(@wiki_result)
    Wiki::QueryService.stubs(:new).returns(wiki_service)

    Messages::StructuredAssistantReply.stub(:call, result) do
      LlmService.stub(:stream, ->(*) { raise "stream should not be called" }) do
        RagQueryJob.perform_now(ai_message.id)
      end
    end

    ai_message.reload
    assert_not ai_message.streaming?
    assert_equal 1, ai_message.structured_tables.size
    assert_includes ai_message.content, "Dados:"
  end

  test "tabular failure shows error and does not fall back to stream" do
    wiki_service = mock("wiki_query")
    wiki_service.stubs(:call).returns(@wiki_result)
    Wiki::QueryService.stubs(:new).returns(wiki_service)

    Messages::StructuredAssistantReply.stubs(:call).raises(Openai::Completion::Error.new("API error"))
    LlmService.stub(:stream, ->(*) { raise "stream should not be called" }) do
      RagQueryJob.perform_now(@ai_message.id)
    end

    @ai_message.reload
    assert_not @ai_message.streaming?
    assert_equal RagQueryJob::TABULAR_ERROR_TEXT, @ai_message.content
    assert_empty @ai_message.structured_tables
    assert_nil @ai_message.metadata["thinking"]
  end

  test "broadcast_thinking persists retrieving payload with chunks_count" do
    job = RagQueryJob.new
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)

    job.send(
      :broadcast_thinking,
      @ai_message,
      @conversation,
      phase: "retrieving",
      intent: :tabular,
      chunks_count: 1,
      tabular: true
    )

    @ai_message.reload
    thinking = @ai_message.metadata["thinking"]
    assert_equal "retrieving", thinking["phase"]
    assert_equal "tabular", thinking["intent"]
    assert_equal 1, thinking["chunks_count"]
    assert @ai_message.streaming?
  end
end

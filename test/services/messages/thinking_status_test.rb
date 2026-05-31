# frozen_string_literal: true

require "test_helper"

module Messages
  class ThinkingStatusTest < ActiveSupport::TestCase
    test "intent_for returns tabular when tabular flag" do
      user_message = Message.new(role: "user", content: "tabela", metadata: {})

      assert_equal :tabular, ThinkingStatus.intent_for(user_message: user_message, tabular: true)
    end

    test "intent_for returns focus when focus_document_id present" do
      user_message = Message.new(
        role: "user",
        content: "resumo",
        metadata: { "focus_document_id" => 42 }
      )

      assert_equal :focus, ThinkingStatus.intent_for(user_message: user_message, tabular: false)
    end

    test "intent_for returns document by default" do
      user_message = Message.new(role: "user", content: "resumo", metadata: {})

      assert_equal :document, ThinkingStatus.intent_for(user_message: user_message, tabular: false)
    end

    test "build retrieving document includes chunks secondary" do
      result = ThinkingStatus.build(phase: :retrieving, intent: :document, chunks_count: 3)

      assert_includes result.primary_label, "documentos"
      assert_includes result.secondary_label, "3"
      assert_includes result.secondary_label, "trechos"
      assert result.show_brand
    end

    test "build retrieving focus uses filename in primary" do
      result = ThinkingStatus.build(
        phase: :retrieving,
        intent: :focus,
        chunks_count: 1,
        focus_document_name: "contrato.pdf"
      )

      assert_includes result.primary_label, "contrato.pdf"
      assert_includes result.secondary_label, "1 trecho"
    end

    test "build generating tabular has no secondary" do
      result = ThinkingStatus.build(phase: :generating, intent: :tabular, chunks_count: 5)

      assert_includes result.primary_label, "tabela"
      assert_nil result.secondary_label
    end

    test "from_metadata returns nil without thinking key" do
      assert_nil ThinkingStatus.from_metadata({})
      assert_nil ThinkingStatus.from_metadata({ "thinking" => {} })
    end

    test "thinking_payload omits blank focus name" do
      payload = ThinkingStatus.thinking_payload(
        phase: "retrieving",
        intent: "document",
        chunks_count: 2,
        focus_document_name: ""
      )

      assert_equal 2, payload["chunks_count"]
      assert_not payload.key?("focus_document_name")
    end
  end
end

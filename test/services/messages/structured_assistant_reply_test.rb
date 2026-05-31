# frozen_string_literal: true

require "test_helper"

module Messages
  class StructuredAssistantReplyTest < ActiveSupport::TestCase
    test "call parses and normalizes OpenAI JSON response" do
      payload = {
        "summary" => "Resumo curto",
        "components" => [
          { "type" => "rich_text", "data" => { "content" => "Texto **bold**" } },
          {
            "type" => "table",
            "data" => { "headers" => %w[A B], "rows" => [["1", "2"]] }
          }
        ]
      }.to_json

      Openai::Completion.stub(:call, payload) do
        result = StructuredAssistantReply.call(
          context: { wiki_chunks: [], doc_chunks: [] },
          history: [],
          user_content: "mostre em tabela",
          mode: :tabular
        )

        assert_equal 1, result.schema_version
        assert_equal "Resumo curto", result.summary
        assert result.components.any? { |c| c["type"] == "table" }
        assert result.components.any? { |c| c["type"] == "rich_text" }
      end
    end

    test "tabular mode raises when response has no table" do
      payload = {
        "summary" => "Só texto",
        "components" => [{ "type" => "rich_text", "data" => { "content" => "Sem tabela" } }]
      }.to_json

      Openai::Completion.stub(:call, payload) do
        assert_raises(AiComponents::Registry::MissingTableError) do
          StructuredAssistantReply.call(
            context: { wiki_chunks: [], doc_chunks: [] },
            history: [],
            user_content: "tabela",
            mode: :tabular
          )
        end
      end
    end
  end
end

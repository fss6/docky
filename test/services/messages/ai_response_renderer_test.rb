# frozen_string_literal: true

require "test_helper"

module Messages
  class AiResponseRendererTest < ActiveSupport::TestCase
    test "renders rich_text with strong tags" do
      html = AiResponseRenderer.render(
        [{ "type" => "rich_text", "data" => { "content" => "**negrito**" } }]
      )

      assert_includes html, "<strong>negrito</strong>"
    end

    test "renders table html" do
      html = AiResponseRenderer.render(
        [
          {
            "type" => "table",
            "data" => {
              "title" => "Dados",
              "headers" => %w[Campo Valor],
              "rows" => [["kWh", "734"]]
            }
          }
        ]
      )

      assert_match %r{<table\b}, html
      assert_includes html, "734"
      assert_includes html, "Dados"
    end

    test "renders alert with title" do
      html = AiResponseRenderer.render(
        [
          {
            "type" => "alert",
            "data" => { "severity" => "warning", "title" => "Atenção", "description" => "Prazo curto" }
          }
        ]
      )

      assert_includes html, "Atenção"
      assert_includes html, "Prazo curto"
    end
  end
end

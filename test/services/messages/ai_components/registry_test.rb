# frozen_string_literal: true

require "test_helper"

module Messages
  module AiComponents
    class RegistryTest < ActiveSupport::TestCase
      test "normalize_payload coerces summary into rich_text when components empty" do
        result = Registry.normalize_payload({ "summary" => "Só resumo", "components" => [] })

        assert_equal 1, result["schema_version"]
        assert_equal 1, result["components"].size
        assert_equal "rich_text", result["components"].first["type"]
        assert_equal "Só resumo", result["components"].first["data"]["content"]
      end

      test "normalize_payload accepts table with headers key" do
        raw = {
          "summary" => "Tabela",
          "components" => [
            {
              "type" => "table",
              "data" => {
                "title" => "Energia",
                "headers" => %w[Mês kWh],
                "rows" => [["abril", "100"]]
              }
            }
          ]
        }

        result = Registry.normalize_payload(raw)
        table = result["components"].first

        assert_equal "table", table["type"]
        assert_equal %w[Mês kWh], table["data"]["headers"]
      end

      test "normalize_payload with require_table raises when no table" do
        raw = {
          "summary" => "Texto",
          "components" => [{ "type" => "rich_text", "data" => { "content" => "Olá" } }]
        }

        assert_raises(Registry::MissingTableError) do
          Registry.normalize_payload(raw, require_table: true)
        end
      end

      test "plain_text_answer aggregates summary and components" do
        text = Registry.plain_text_answer(
          summary: "Resumo",
          components: [
            { "type" => "rich_text", "data" => { "content" => "Corpo" } },
            { "type" => "table", "data" => { "headers" => %w[A B], "rows" => [["1", "2"]] } }
          ]
        )

        assert_includes text, "Resumo"
        assert_includes text, "Corpo"
        assert_includes text, "A | B"
      end

      test "normalize_payload normalizes alert severity" do
        raw = {
          "summary" => "",
          "components" => [
            {
              "type" => "alert",
              "data" => { "severity" => "invalid", "title" => "Aviso", "description" => "Detalhe" }
            },
            { "type" => "rich_text", "data" => { "content" => "x" } }
          ]
        }

        result = Registry.normalize_payload(raw)
        alert = result["components"].find { |c| c["type"] == "alert" }

        assert_equal "info", alert["data"]["severity"]
      end
    end
  end
end

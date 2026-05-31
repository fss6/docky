# frozen_string_literal: true

require "test_helper"

module Messages
  class StripInlineCitationsTest < ActiveSupport::TestCase
    test "removes parenthetical Fonte citation" do
      text = "Resumo do período.\n\n(Fonte: relatorio.pdf · p. 0 e p. 1)"
      assert_equal "Resumo do período.", StripInlineCitations.call(text)
    end

    test "removes standalone Fonte line" do
      text = "Texto.\nFonte: arquivo.pdf · p. 2"
      assert_equal "Texto.", StripInlineCitations.call(text)
    end

    test "strip_components cleans rich_text content" do
      components = [
        { "type" => "rich_text", "data" => { "content" => "Olá.\n\n(Fonte: x.pdf · p. 1)" } }
      ]
      out = StripInlineCitations.strip_components(components)
      assert_equal "Olá.", out.first["data"]["content"]
    end
  end
end

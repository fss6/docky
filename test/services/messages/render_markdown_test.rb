# frozen_string_literal: true

require "test_helper"

module Messages
  class RenderMarkdownTest < ActiveSupport::TestCase
    test "renders valid bold markdown" do
      html = RenderMarkdown.call("**Período:** abril de 2026")

      assert_includes html, "<strong>Período:</strong>"
      assert_not_includes html, "**"
    end

    test "renders valid gfm table" do
      input = <<~MD.strip
        | Mês | kWh |
        | --- | --- |
        | Novembro 2025 | 714 |
      MD
      html = RenderMarkdown.call(input)

      assert_includes html, "<table>"
      assert_includes html, "<th>"
      assert_includes html, "Novembro 2025"
    end

    test "does not fix invalid spaced bold" do
      html = RenderMarkdown.call("** Período:** abril")

      assert_includes html, "**"
    end
  end
end

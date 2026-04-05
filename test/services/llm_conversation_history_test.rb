# frozen_string_literal: true

require "test_helper"

class LlmConversationHistoryTest < ActiveSupport::TestCase
  test "trim keeps order and respects max messages" do
    msgs = 30.times.map do |i|
      { role: i.even? ? "user" : "assistant", content: "m#{i}" }
    end
    out = LlmConversationHistory.trim(msgs)
    assert_equal 24, out.size
    assert_equal "m6", out.first[:content]
    assert_equal "m29", out.last[:content]
  end

  test "trim drops oldest until under char budget" do
    msgs = [
      { role: "user", content: "a" * 5_000 },
      { role: "assistant", content: "b" * 5_000 },
      { role: "user", content: "last" }
    ]
    out = LlmConversationHistory.trim(msgs)
    assert out.sum { |m| m[:content].length } <= LlmConversationHistory::MAX_TOTAL_CHARS
    assert_equal "last", out.last[:content]
  end

  test "trim skips blank and unknown roles" do
    msgs = [
      { role: "user", content: "ok" },
      { role: "assistant", content: "   " },
      { role: "system", content: "no" },
      { role: "user", content: "end" }
    ]
    out = LlmConversationHistory.trim(msgs)
    assert_equal 2, out.size
    assert_equal %w[user user], out.map { |m| m[:role] }
  end
end

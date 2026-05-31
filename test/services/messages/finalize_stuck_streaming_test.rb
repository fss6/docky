# frozen_string_literal: true

require "test_helper"

module Messages
  class FinalizeStuckStreamingTest < ActiveSupport::TestCase
    test "finalizes assistant messages stuck in streaming state" do
      conversation = conversations(:one)
      message = conversation.messages.create!(
        role: "assistant",
        content: "Resposta incompleta",
        streaming: true
      )
      message.update_column(:updated_at, 3.minutes.ago)

      FinalizeStuckStreaming.call([message])

      assert_not message.reload.streaming?
    end

    test "does not finalize recent streaming messages" do
      conversation = conversations(:one)
      message = conversation.messages.create!(
        role: "assistant",
        content: "",
        streaming: true
      )

      FinalizeStuckStreaming.call([message])

      assert message.reload.streaming?
    end
  end
end

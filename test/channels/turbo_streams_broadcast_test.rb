# frozen_string_literal: true

require "test_helper"

class TurboStreamsBroadcastTest < ActionCable::TestCase
  include ActionCable::TestHelper

  test "broadcast_replace_to publishes turbo stream to conversation channel" do
    conversation = conversations(:one)
    stream = "conversation_#{conversation.id}"

    assert_broadcasts(stream, 1) do
      Turbo::StreamsChannel.broadcast_replace_to(
        stream,
        target: "message_content_test",
        html: "<div id=\"message_content_test\">Resposta parcial</div>"
      )
    end

    payload = broadcasts(stream).last
    assert_includes payload, "turbo-stream"
    assert_includes payload, "message_content_test"
  end
end

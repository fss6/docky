# frozen_string_literal: true

require "test_helper"

class PublicUploads::BlockedMessageTest < ActiveSupport::TestCase
  test "period_missing message is client-friendly" do
    message = PublicUploads::BlockedMessage.for(kind: :period_missing)

    assert_includes message, "períodos abertos"
    assert_not_includes message.downcase, "competência"
  end

  test "period_closed message includes formatted period label" do
    period = Date.new(2026, 5, 1)
    message = PublicUploads::BlockedMessage.for(kind: :period_closed, period: period)

    assert_includes message, "Maio/2026"
    assert_includes message, "não está recebendo documentos"
    assert_not_includes message.downcase, "competência"
  end
end

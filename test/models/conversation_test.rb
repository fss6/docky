require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "default_title? is true for blank or default placeholder" do
    conv = conversations(:one)
    conv.update!(title: nil)
    assert conv.default_title?

    conv.update!(title: Conversation::DEFAULT_TITLE)
    assert conv.default_title?

    conv.update!(title: "Custom")
    assert_not conv.default_title?
  end
end

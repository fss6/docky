require "test_helper"

class AuditEventTest < ActiveSupport::TestCase
  test "is invalid without event_type" do
    event = AuditEvent.new(
      account: accounts(:one),
      user: users(:one),
      subject: folders(:one),
      metadata: {}
    )

    assert_not event.valid?
    assert_includes event.errors[:event_type], "não pode ficar em branco"
  end

  test "recorder persists metadata and optional user" do
    event = AuditEvents::Recorder.call(
      account: accounts(:one),
      event_type: "document.tag_removed",
      subject: folders(:one),
      metadata: { tag: "fiscal" }
    )

    assert_predicate event, :persisted?
    assert_nil event.user
    assert_equal "fiscal", event.metadata["tag"]
  end
end

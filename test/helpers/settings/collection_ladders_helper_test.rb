# frozen_string_literal: true

require "test_helper"

class Settings::CollectionLaddersHelperTest < ActiveSupport::TestCase
  include Settings::CollectionLaddersHelper

  test "offset code formatting" do
    assert_equal "-3d", collection_step_offset_code(collection_steps(:friendly))
    assert_equal "0d", collection_step_offset_code(collection_steps(:firm))
    assert_equal "+5d", collection_step_offset_code(collection_steps(:manager_alert))
  end

  test "timing phrases relative to deadline" do
    assert_equal "3 dias antes do prazo", collection_step_timing_phrase(collection_steps(:friendly))
    assert_equal "No dia do prazo", collection_step_timing_phrase(collection_steps(:firm))
    assert_equal "5 dias após o prazo · interno", collection_step_timing_phrase(collection_steps(:manager_alert))

    late = CollectionStep.new(offset_days: 2, kind: :client_reminder, name: "Atraso")
    assert_equal "2 dias após o prazo", collection_step_timing_phrase(late)
  end

  test "timing icons and tones" do
    assert_equal "calendar-days", collection_step_timing_icon(collection_steps(:friendly))
    assert_equal :before, collection_step_timing_tone(collection_steps(:friendly))

    assert_equal "calendar", collection_step_timing_icon(collection_steps(:firm))
    assert_equal :due, collection_step_timing_tone(collection_steps(:firm))

    late = CollectionStep.new(offset_days: 2, kind: :client_reminder, name: "Atraso")
    assert_equal "exclamation-triangle", collection_step_timing_icon(late)
    assert_equal :after, collection_step_timing_tone(late)

    assert_equal "building-office", collection_step_timing_icon(collection_steps(:manager_alert))
    assert_equal :internal, collection_step_timing_tone(collection_steps(:manager_alert))
  end

  test "aria label combines phrase and step name" do
    label = collection_step_timing_aria_label(collection_steps(:friendly))
    assert_includes label, "3 dias antes do prazo"
    assert_includes label, "Lembrete amigável"
  end
end

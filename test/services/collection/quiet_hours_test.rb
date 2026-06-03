# frozen_string_literal: true

require "test_helper"

module Collection
  class QuietHoursTest < ActiveSupport::TestCase
    setup do
      @settings = collection_settings(:one)
      @settings.update!(
        timezone: "America/Sao_Paulo",
        quiet_hours_start: time_at("08:00"),
        quiet_hours_end: time_at("19:00")
      )
      @zone = ActiveSupport::TimeZone[@settings.timezone]
    end

    test "inside allowed window returns false" do
      at = @zone.local(2026, 6, 3, 10, 0, 0)
      assert_not QuietHours.outside?(settings: @settings, at: at)
    end

    test "before window start returns true" do
      at = @zone.local(2026, 6, 3, 7, 0, 0)
      assert QuietHours.outside?(settings: @settings, at: at)
    end

    test "after window end returns true" do
      at = @zone.local(2026, 6, 3, 20, 0, 0)
      assert QuietHours.outside?(settings: @settings, at: at)
    end

    test "overnight range follows implementation semantics" do
      @settings.update!(
        quiet_hours_start: time_at("22:00"),
        quiet_hours_end: time_at("06:00")
      )

      assert_not QuietHours.outside?(settings: @settings, at: @zone.local(2026, 6, 3, 23, 0, 0))
      assert QuietHours.outside?(settings: @settings, at: @zone.local(2026, 6, 3, 12, 0, 0))
    end

    private

    def time_at(hour_minute)
      Time.zone.parse("2000-01-01 #{hour_minute}:00")
    end
  end
end

# frozen_string_literal: true

module Collection
  class QuietHours
    def self.outside?(settings:, at: Time.current)
      new(settings: settings, at: at).outside?
    end

    def initialize(settings:, at:)
      @settings = settings
      @at = at.in_time_zone(@settings.timezone)
    end

    def outside?
      start_t = @settings.quiet_hours_start
      end_t = @settings.quiet_hours_end
      return false if start_t.blank? || end_t.blank?

      current = @at.strftime("%H:%M:%S")
      start_s = start_t.strftime("%H:%M:%S")
      end_s = end_t.strftime("%H:%M:%S")

      if start_s <= end_s
        current < start_s || current >= end_s
      else
        current >= end_s && current < start_s
      end
    end
  end
end

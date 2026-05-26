# frozen_string_literal: true

module Onboarding
  class Progress
    Result = Struct.new(
      :received_count,
      :total_count,
      :percent,
      :pending_names,
      :started_at,
      :days_since_start,
      keyword_init: true
    )

    def self.call(checklist:)
      new(checklist: checklist).call
    end

    def initialize(checklist:)
      @checklist = checklist
    end

    def call
      items = @checklist.items.ordered.to_a
      total = items.size
      received = items.count(&:complete?)
      pending_names = items.reject(&:complete?).map(&:name)
      percent = total.positive? ? ((received.to_f / total) * 100).round : 0
      started_at = @checklist.started_at
      days = started_at ? ((Time.current - started_at) / 1.day).floor : 0

      Result.new(
        received_count: received,
        total_count: total,
        percent: percent,
        pending_names: pending_names,
        started_at: started_at,
        days_since_start: days
      )
    end
  end
end

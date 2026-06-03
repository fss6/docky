# frozen_string_literal: true

module Settings
  module CollectionLaddersHelper
    TIMING_TONE_STYLES = {
      before: {
        icon_circle: "bg-blue-50 text-blue-700 ring-blue-100",
        badge: "bg-blue-50 text-blue-800 border-blue-200",
        timeline: "bg-blue-50/80 text-blue-900 border-blue-200/80"
      },
      due: {
        icon_circle: "bg-accent/10 text-accent ring-accent/20",
        badge: "bg-accent/10 text-accent border-accent/30",
        timeline: "bg-accent/5 text-zinc-900 border-accent/25"
      },
      after: {
        icon_circle: "bg-amber-50 text-amber-800 ring-amber-100",
        badge: "bg-amber-50 text-amber-900 border-amber-200",
        timeline: "bg-amber-50/80 text-amber-950 border-amber-200/80"
      },
      internal: {
        icon_circle: "bg-zinc-100 text-zinc-700 ring-zinc-200",
        badge: "bg-zinc-100 text-zinc-700 border-zinc-200",
        timeline: "bg-zinc-50 text-zinc-800 border-zinc-200"
      }
    }.freeze

    def collection_step_offset_code(step)
      days = step.offset_days
      days.positive? ? "+#{days}d" : "#{days}d"
    end

    def collection_step_timing_phrase(step)
      days = step.offset_days.abs

      if step.offset_days.negative?
        pluralize_days(days, "antes do prazo")
      elsif step.offset_days.zero?
        "No dia do prazo"
      elsif step.kind_internal_alert?
        "#{pluralize_days(days, 'após o prazo')} · interno"
      else
        pluralize_days(days, "após o prazo")
      end
    end

    def collection_step_timing_icon(step)
      return "building-office" if step.kind_internal_alert?
      return "calendar" if step.offset_days.zero?
      return "calendar-days" if step.offset_days.negative?

      "exclamation-triangle"
    end

    def collection_step_timing_tone(step)
      return :internal if step.kind_internal_alert?
      return :before if step.offset_days.negative?
      return :due if step.offset_days.zero?

      :after
    end

    def collection_step_timing_styles(step, variant: :badge)
      tone = collection_step_timing_tone(step)
      TIMING_TONE_STYLES.fetch(tone).fetch(variant)
    end

    def collection_step_timing_aria_label(step)
      "Etapa #{collection_step_timing_phrase(step)}: #{step.name}"
    end

    private

    def pluralize_days(count, suffix)
      return "No dia do prazo" if count.zero?

      unit = count == 1 ? "1 dia" : "#{count} dias"
      "#{unit} #{suffix}"
    end
  end
end

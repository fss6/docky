# frozen_string_literal: true

module Messages
  # Copy e payload do indicador "A pensar" (fases honestas: retrieving → generating).
  # Extensão v2: padrões de domínio (NF, tributário) em DOMAIN_PATTERNS — não na v1.
  class ThinkingStatus
    Result = Struct.new(:primary_label, :secondary_label, :show_brand, keyword_init: true)

    PHASES = %w[retrieving generating].freeze
    INTENTS = %w[tabular focus document].freeze

    def self.intent_for(user_message:, tabular:)
      return :tabular if tabular
      return :focus if user_message.focus_document_id.present?

      :document
    end

    def self.build(phase:, intent:, chunks_count: 0, focus_document_name: nil)
      phase_s = phase.to_s
      intent_s = intent.to_s
      phase_s = "retrieving" unless PHASES.include?(phase_s)
      intent_s = "document" unless INTENTS.include?(intent_s)

      filename = focus_document_name.to_s.presence
      primary = I18n.t(
        "messages.chat.thinking_status.#{phase_s}.#{intent_s}.primary",
        filename: filename,
        default: I18n.t("messages.chat.thinking")
      )

      secondary =
        if phase_s == "retrieving" && chunks_count.to_i.positive?
          I18n.t("messages.chat.thinking_status.chunks_found", count: chunks_count.to_i)
        end

      Result.new(
        primary_label: primary,
        secondary_label: secondary,
        show_brand: true
      )
    end

    def self.from_metadata(metadata)
      return nil unless metadata.is_a?(Hash)

      thinking = metadata["thinking"]
      return nil unless thinking.is_a?(Hash)
      return nil if thinking["phase"].blank?

      build(
        phase: thinking["phase"],
        intent: thinking["intent"],
        chunks_count: thinking["chunks_count"],
        focus_document_name: thinking["focus_document_name"]
      )
    end

    def self.thinking_payload(phase:, intent:, chunks_count: 0, focus_document_name: nil)
      payload = {
        "phase" => phase.to_s,
        "intent" => intent.to_s,
        "chunks_count" => chunks_count.to_i
      }
      name = focus_document_name.to_s.presence
      payload["focus_document_name"] = name if name.present?
      payload
    end
  end
end

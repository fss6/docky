# frozen_string_literal: true

module MessagesHelper
  def thinking_indicator_locals(message)
    status = Messages::ThinkingStatus.from_metadata(message.metadata)
    if status
      return {
        primary_label: status.primary_label,
        secondary_label: status.secondary_label,
        show_brand: status.show_brand
      }
    end

    meta = message.metadata
    if meta.is_a?(Hash) && meta["loading"] == "tabular"
      return {
        primary_label: t("messages.chat.preparing_table"),
        secondary_label: nil,
        show_brand: false
      }
    end

    {
      primary_label: t("messages.chat.thinking"),
      secondary_label: nil,
      show_brand: false
    }
  end
end

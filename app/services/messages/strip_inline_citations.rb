# frozen_string_literal: true

module Messages
  # Remove referências inline a fontes que o painel de contexto já exibe.
  class StripInlineCitations
    FONTE_PAREN_RE = /\s*\(?\s*Fonte:\s*[^)\n]+(?:\)|\z)/mi
    FONTE_LINE_RE = /^\s*Fonte:\s*[^\n]+$/mi
    BRACKET_FONTE_RE = /^\s*\[Fonte\]\s*$/mi

    def self.call(text)
      return "" if text.blank?

      cleaned = text.to_s.dup
      cleaned.gsub!(FONTE_PAREN_RE, "")
      cleaned.gsub!(FONTE_LINE_RE, "")
      cleaned.gsub!(BRACKET_FONTE_RE, "")
      cleaned.gsub!(/\n{3,}/, "\n\n")
      cleaned.strip
    end

    def self.strip_components(components)
      Array(components).map do |component|
        next component unless component.is_a?(Hash)
        next component unless %w[rich_text fallback].include?(component["type"])

        data = (component["data"] || {}).dup
        data["content"] = call(data["content"])
        component.merge("data" => data)
      end
    end
  end
end

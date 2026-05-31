# frozen_string_literal: true

module Messages
  module AiComponents
    # Valida e normaliza componentes da resposta estruturada da IA (schema v1).
    class Registry
      SCHEMA_VERSION = 1
      TYPES = %w[rich_text table alert action_list fallback].freeze
      ALERT_SEVERITIES = %w[info success warning error].freeze

      class ValidationError < StandardError; end
      class EmptyResponseError < StandardError; end
      class MissingTableError < StandardError; end

      def self.normalize_payload(raw, require_table: false)
        new(raw, require_table: require_table).normalize_payload
      end

      def self.plain_text_answer(summary:, components:)
        parts = []
        parts << summary.to_s.strip if summary.present?
        Array(components).each do |component|
          parts << plain_text_for_component(component)
        end
        parts.compact.join("\n\n").strip
      end

      def self.plain_text_for_component(component)
        type = component["type"]
        data = component["data"] || {}
        case type
        when "rich_text", "fallback"
          data["content"].to_s
        when "table"
          title = data["title"].presence
          headers = Array(data["headers"])
          rows = Array(data["rows"])
          row_text = rows.map { |row| Array(row).join(" | ") }.join("\n")
          [title, headers.join(" | "), row_text].compact.join("\n")
        when "alert"
          [data["title"], data["description"]].compact.join(": ")
        when "action_list"
          title = data["title"].presence
          actions = Array(data["actions"]).map(&:to_s).reject(&:blank?)
          ([title] + actions).compact.join("\n")
        else
          ""
        end
      end

      def initialize(raw, require_table: false)
        @raw = raw
        @require_table = require_table
      end

      def normalize_payload
        data = @raw.is_a?(Hash) ? @raw : {}
        summary = data["summary"].to_s.strip
        components = Array(data["components"]).filter_map { |item| normalize_component(item) }

        components = coerce_fallback(summary, components)
        validate_presence!(components)
        validate_tabular_requirement!(components) if @require_table

        {
          "schema_version" => SCHEMA_VERSION,
          "summary" => summary,
          "components" => components
        }
      end

      private

      def normalize_component(item)
        return nil unless item.is_a?(Hash)

        type = item["type"].to_s.strip
        type = "fallback" if type.blank?
        type = "rich_text" if type == "fallback" && item.dig("data", "content").present?
        return nil unless TYPES.include?(type)

        data = normalize_data(type, item["data"])
        return nil if data.blank?

        { "type" => type, "data" => data }
      end

      def normalize_data(type, raw_data)
        data = raw_data.is_a?(Hash) ? raw_data.stringify_keys : {}
        case type
        when "rich_text", "fallback"
          content = data["content"].to_s.strip
          return nil if content.blank?

          { "content" => content }
        when "table"
          headers = Array(data["headers"].presence || data["columns"]).map { |c| c.to_s.strip }.reject(&:blank?)
          rows = Array(data["rows"]).map { |row| Array(row).map { |cell| cell.to_s.strip } }
          return nil if headers.blank? || rows.blank?

          {
            "title" => data["title"].to_s.strip.presence,
            "headers" => headers,
            "rows" => rows
          }
        when "alert"
          severity = data["severity"].to_s.strip.downcase
          severity = "info" unless ALERT_SEVERITIES.include?(severity)
          title = data["title"].to_s.strip
          description = data["description"].to_s.strip
          return nil if title.blank? && description.blank?

          { "severity" => severity, "title" => title, "description" => description }
        when "action_list"
          actions = Array(data["actions"]).map { |a| a.to_s.strip }.reject(&:blank?)
          return nil if actions.blank?

          {
            "title" => data["title"].to_s.strip.presence,
            "actions" => actions
          }
        end
      end

      def coerce_fallback(summary, components)
        return components if components.any?

        return components if summary.blank?

        components + [{ "type" => "rich_text", "data" => { "content" => summary } }]
      end

      def validate_presence!(components)
        raise EmptyResponseError, "resposta sem componentes" if components.blank?
      end

      def validate_tabular_requirement!(components)
        return if components.any? { |c| c["type"] == "table" }

        raise MissingTableError, "resposta tabular sem componente table"
      end
    end
  end
end

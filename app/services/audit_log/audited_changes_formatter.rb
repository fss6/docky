# frozen_string_literal: true

module AuditLog
  class AuditedChangesFormatter
    ACTION_LABELS = {
      "create" => "Criado",
      "update" => "Atualizado",
      "destroy" => "Excluído"
    }.freeze

    ATTRIBUTE_LABELS = {
      "Folder" => {
        "name" => "Nome",
        "visible" => "Visível",
        "client_id" => "Cliente"
      }
    }.freeze

    def initialize(auditable_type:, action:, audited_changes:)
      @auditable_type = auditable_type.to_s
      @action = action.to_s
      @audited_changes = parse_changes(audited_changes)
    end

    def action_label
      ACTION_LABELS.fetch(@action, @action.humanize)
    end

    def summary
      return "—" if @audited_changes.blank?

      parts = @audited_changes.map { |attribute, value| format_change(attribute, value) }
      parts.compact.join(" · ").presence || "—"
    end

    private

    def parse_changes(raw)
      return raw if raw.is_a?(Hash)
      return {} if raw.blank?

      YAML.safe_load(raw.to_s, permitted_classes: [Symbol], aliases: true) || {}
    rescue Psych::Exception, ArgumentError
      {}
    end

    def format_change(attribute, value)
      label = attribute_label(attribute)
      formatted_value = format_value(attribute, value)
      return nil if formatted_value.blank?

      "#{label}: #{formatted_value}"
    end

    def attribute_label(attribute)
      ATTRIBUTE_LABELS.dig(@auditable_type, attribute) || attribute.humanize
    end

    def format_value(attribute, value)
      case @action
      when "create"
        display_scalar(value.is_a?(Array) ? value.last : value, attribute)
      when "destroy"
        display_scalar(value.is_a?(Array) ? value.first : value, attribute)
      else
        format_update_value(value, attribute)
      end
    end

    def format_update_value(value, attribute)
      if value.is_a?(Array) && value.size == 2
        before, after = value
        "#{display_scalar(before, attribute)} → #{display_scalar(after, attribute)}"
      else
        display_scalar(value, attribute)
      end
    end

    def display_scalar(value, attribute)
      case attribute
      when "client_id"
        client_display(value)
      when "visible"
        value == true || value.to_s == "true" ? "Sim" : "Não"
      else
        value.nil? ? "—" : value.to_s
      end
    end

    def client_display(client_id)
      return "—" if client_id.blank?

      Client.find_by(id: client_id)&.name || "##{client_id}"
    end
  end
end

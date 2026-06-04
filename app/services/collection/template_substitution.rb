# frozen_string_literal: true

module Collection
  module TemplateSubstitution
    PLACEHOLDERS = %w[cliente documentos_faltantes prazo link_upload escritorio].freeze

    module_function

    def render_template(template, replacements)
      text = template.to_s
      PLACEHOLDERS.each do |key|
        text = text.gsub("{#{key}}", replacements.fetch(key))
      end
      text
    end
  end
end

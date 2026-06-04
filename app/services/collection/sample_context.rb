# frozen_string_literal: true

module Collection
  class SampleContext
    SAMPLE_UPLOAD_URL = "https://app.exemplo.com/portal/exemplo-token/upload"

    def self.default_step_templates
      SeedDefaultSteps::DEFAULT_STEPS.find { |step| step[:offset_days] == -3 } ||
        SeedDefaultSteps::DEFAULT_STEPS.first
    end

    def render_template(template)
      TemplateSubstitution.render_template(template, replacements)
    end

    def replacements
      @replacements ||= {
        "cliente" => "Cliente Exemplo Ltda.",
        "documentos_faltantes" => "- Nota Fiscal\n- Extrato Bancário",
        "prazo" => I18n.l(10.days.from_now.to_date, format: :short),
        "link_upload" => SAMPLE_UPLOAD_URL,
        "escritorio" => "Escritório Exemplo"
      }
    end
  end
end

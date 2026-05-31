# frozen_string_literal: true

module Onboarding
  class SeedDefaultTemplates
    TEMPLATES = {
      "mei" => {
        name: "MEI / Microempreendedor",
        items: [
          { name: "CCMEI atualizado", help_text: nil },
          { name: "RG / CPF", help_text: nil },
          { name: "Comprovante de endereço", help_text: "Conta de luz, água ou telefone dos últimos 3 meses" },
          { name: "Dados bancários", help_text: nil },
          { name: "Certificado digital (opcional)", help_text: "A1 ou A3, se já possuir" }
        ]
      },
      "new_company" => {
        name: "Empresa nova (constituição)",
        items: [
          { name: "Contrato social", help_text: nil },
          { name: "Requerimento de empresário / CCMEI", help_text: nil },
          { name: "Comprovante de inscrição CNPJ", help_text: nil },
          { name: "RG / CPF dos sócios", help_text: nil },
          { name: "Certificado digital (A1 ou A3)", help_text: "Não tem? Consulte sua contabilidade sobre como obter." },
          { name: "Procuração eletrônica e-CAC", help_text: "Permite que sua contabilidade acesse o e-CAC em seu nome" },
          { name: "Dados bancários", help_text: nil }
        ]
      },
      "migration" => {
        name: "Migração de contabilidade",
        items: [
          { name: "Contrato social", help_text: nil },
          { name: "Requerimento de empresário / CCMEI", help_text: nil },
          { name: "Comprovante de inscrição CNPJ", help_text: nil },
          { name: "RG / CPF dos sócios", help_text: nil },
          { name: "Certificado digital (A1 ou A3)", help_text: nil },
          { name: "Procuração eletrônica e-CAC", help_text: nil },
          { name: "Dados bancários", help_text: nil },
          { name: "Último balancete", help_text: "Da contabilidade anterior" },
          { name: "Última ECD / ECF", help_text: nil },
          { name: "Último IRPJ", help_text: nil },
          { name: "Situação fiscal e-CAC", help_text: nil },
          { name: "Declaração de regularidade da contabilidade anterior", help_text: nil }
        ]
      }
    }.freeze

    def self.call(account:)
      new(account: account).call
    end

    def initialize(account:)
      @account = account
    end

    def call
      ActsAsTenant.with_tenant(@account) do
        TEMPLATES.each_with_index do |(kind, config), index|
          template = OnboardingTemplate.find_or_initialize_by(account: @account, kind: kind)
          seed_template!(template, config:, position: index)
        end
      end
    end

    private

    def seed_template!(template, config:, position:)
      template.name = config[:name] if template.new_record? || template.name.blank?
      template.position = position if template.new_record?
      template.system = true
      template.save!

      return if template.items.exists?

      config[:items].each_with_index do |item_config, item_index|
        template.items.create!(
          name: item_config[:name],
          help_text: item_config[:help_text],
          position: item_index
        )
      end
    end
  end
end

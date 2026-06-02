# frozen_string_literal: true

module Collection
  class SeedDefaultSteps
    DEFAULT_STEPS = [
      {
        position: 0,
        offset_days: -3,
        name: "Lembrete amigável",
        kind: :client_reminder,
        email_enabled: true,
        whatsapp_enabled: false,
        email_subject_template: "Faltam alguns documentos do seu mês",
        email_body_template: <<~TEXT.strip,
          Oi {cliente}!

          Estamos montando a contabilidade do mês e ainda faltam alguns documentos seus:

          {documentos_faltantes}

          É rapidinho — dá pra enviar tudo por aqui, sem login: {link_upload}

          Prazo: {prazo}. Qualquer dúvida, é só responder este e-mail.

          — {escritorio}
        TEXT
        whatsapp_body_template: <<~TEXT.strip,
          Oi {cliente}! Estamos montando a contabilidade do mês e ainda faltam:

          {documentos_faltantes}

          Envie por aqui: {link_upload}
          Prazo: {prazo}. — {escritorio}
        TEXT
        whatsapp_template_name: nil
      },
      {
        position: 1,
        offset_days: 0,
        name: "Lembrete firme",
        kind: :client_reminder,
        email_enabled: true,
        whatsapp_enabled: true,
        email_subject_template: "Hoje é o prazo dos seus documentos",
        email_body_template: <<~TEXT.strip,
          {cliente}, hoje é o prazo final para os documentos do mês.

          Ainda faltam:
          {documentos_faltantes}

          Envie agora pra não atrasar sua contabilidade: {link_upload}

          — {escritorio}
        TEXT
        whatsapp_body_template: <<~TEXT.strip,
          {cliente}, hoje é o prazo final. Ainda faltam: {documentos_faltantes}. Envie: {link_upload}
        TEXT
        whatsapp_template_name: "cobranca_lembrete_firme"
      },
      {
        position: 2,
        offset_days: 2,
        name: "Alerta de atraso",
        kind: :client_reminder,
        email_enabled: false,
        whatsapp_enabled: true,
        email_subject_template: "Documentos em atraso",
        email_body_template: "{cliente}, seus documentos estão atrasados. Pendente: {documentos_faltantes}. {link_upload}",
        whatsapp_body_template: <<~TEXT.strip,
          {cliente}, seus documentos estão atrasados.

          Pendente:
          {documentos_faltantes}

          Resolva em 1 clique: {link_upload}
        TEXT
        whatsapp_template_name: "cobranca_alerta_atraso"
      },
      {
        position: 3,
        offset_days: 5,
        name: "Avisar o gestor do escritório",
        kind: :internal_alert,
        email_enabled: true,
        whatsapp_enabled: false,
        email_subject_template: "Cliente com documentos pendentes há 5 dias",
        email_body_template: <<~TEXT.strip,
          Cliente {cliente} está com documentos pendentes há 5 dias após o prazo.

          Pendente: {documentos_faltantes}

          Vale um contato direto da equipe.
        TEXT
        whatsapp_body_template: nil,
        whatsapp_template_name: nil
      }
    ].freeze

    def self.call(account:)
      new(account: account).call
    end

    def initialize(account:)
      @account = account
    end

    def call
      return if @account.collection_steps.exists?

      DEFAULT_STEPS.each do |attrs|
        @account.collection_steps.create!(attrs)
      end
    end
  end
end

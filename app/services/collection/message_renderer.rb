# frozen_string_literal: true

module Collection
  class MessageRenderer
    PLACEHOLDERS = TemplateSubstitution::PLACEHOLDERS

    Result = Struct.new(:email_subject, :email_body, :whatsapp_body, keyword_init: true)

    def self.call(client:, period:, period_record:, pending_items:, upload_url:, account:)
      new(
        client: client,
        period: period,
        period_record: period_record,
        pending_items: pending_items,
        upload_url: upload_url,
        account: account
      ).call
    end

    def initialize(client:, period:, period_record:, pending_items:, upload_url:, account:)
      @client = client
      @period = period
      @period_record = period_record
      @pending_items = pending_items
      @upload_url = upload_url
      @account = account
    end

    def render_template(template, step:)
      TemplateSubstitution.render_template(template, replacements)
    end

    def call
      Result.new(
        email_subject: nil,
        email_body: nil,
        whatsapp_body: nil
      )
    end

    def replacements
      @replacements ||= {
        "cliente" => @client.name.to_s,
        "documentos_faltantes" => documents_list,
        "prazo" => prazo_label,
        "link_upload" => @upload_url.to_s,
        "escritorio" => @account.name.to_s
      }
    end

    private

    def documents_list
      names = @pending_items.map { |item| "- #{item.name_snapshot}" }
      names.presence&.join("\n") || "—"
    end

    def prazo_label
      deadline = Deadline.for(client: @client, period: @period)
      I18n.l(deadline, format: :short)
    end
  end
end

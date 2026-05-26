# frozen_string_literal: true

class UploadShareMessageRenderer
  PLACEHOLDERS = %w[nome_cliente link competencia].freeze

  Result = Struct.new(:whatsapp_text, :email_subject, :email_body, keyword_init: true)

  def self.call(setting:, client:, url:, period: nil)
    new(setting: setting, client: client, url: url, period: period).call
  end

  def initialize(setting:, client:, url:, period: nil)
    @setting = setting
    @client = client
    @url = url.to_s
    @period = period
  end

  def call
    Result.new(
      whatsapp_text: render(@setting.upload_share_whatsapp_template),
      email_subject: render(@setting.upload_share_email_subject_template),
      email_body: render(@setting.upload_share_email_body_template)
    )
  end

  private

  def render(template)
    text = template.to_s
    PLACEHOLDERS.each do |key|
      text = text.gsub("{{#{key}}}", replacements.fetch(key))
    end
    text
  end

  def replacements
    @replacements ||= {
      "nome_cliente" => @client.name.to_s,
      "link" => @url,
      "competencia" => period_label
    }
  end

  def period_label
    return "—" if @period.blank?

    PeriodFormatting.display_label(@period)
  end
end

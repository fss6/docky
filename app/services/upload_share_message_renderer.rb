# frozen_string_literal: true

class UploadShareMessageRenderer
  MONTHLY_PLACEHOLDERS = %w[nome_cliente link competencia].freeze
  ONBOARDING_PLACEHOLDERS = %w[nome_cliente link progresso].freeze

  Result = Struct.new(:whatsapp_text, :email_subject, :email_body, keyword_init: true)

  def self.call(setting:, client:, url:, period: nil, context: :monthly, progress: nil)
    new(setting: setting, client: client, url: url, period: period, context: context, progress: progress).call
  end

  def initialize(setting:, client:, url:, period: nil, context: :monthly, progress: nil)
    @setting = setting
    @client = client
    @url = url.to_s
    @period = period
    @context = context.to_sym
    @progress = progress
  end

  def call
    if @context == :onboarding
      Result.new(
        whatsapp_text: render(@setting.onboarding_share_whatsapp_template, ONBOARDING_PLACEHOLDERS),
        email_subject: render(@setting.onboarding_share_email_subject_template, ONBOARDING_PLACEHOLDERS),
        email_body: render(@setting.onboarding_share_email_body_template, ONBOARDING_PLACEHOLDERS)
      )
    else
      Result.new(
        whatsapp_text: render(@setting.upload_share_whatsapp_template, MONTHLY_PLACEHOLDERS),
        email_subject: render(@setting.upload_share_email_subject_template, MONTHLY_PLACEHOLDERS),
        email_body: render(@setting.upload_share_email_body_template, MONTHLY_PLACEHOLDERS)
      )
    end
  end

  private

  def render(template, allowed_keys)
    text = template.to_s
    allowed_keys.each do |key|
      text = text.gsub("{{#{key}}}", replacements.fetch(key))
    end
    text
  end

  def replacements
    @replacements ||= {
      "nome_cliente" => @client.name.to_s,
      "link" => @url,
      "competencia" => period_label,
      "progresso" => progress_label
    }
  end

  def period_label
    return "—" if @period.blank?

    PeriodFormatting.display_label(@period)
  end

  def progress_label
    return "—" if @progress.blank?

    "#{@progress.received_count} de #{@progress.total_count}"
  end
end

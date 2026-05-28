# frozen_string_literal: true

module MailerHelper
  DOKIVO_BRAND_COLOR = "#1a6fff"

  LINK_ONLY_LINE = /\A\s*((pelo|use o|acesse o)\s+)?(link|botão)\s+abaixo:?\s*\z/i

  def upload_invite_email_body_html(body, upload_url:, client:, period: nil)
    client_name = client.name.to_s
    period_label = period.present? ? PeriodFormatting.display_label(period) : nil
    stripped = strip_link_from_email_body(body.to_s, upload_url)
    highlighted = highlight_email_body_text(stripped, client_name: client_name, period_label: period_label)
    simple_format(highlighted, {}, sanitize: false)
  end

  def strip_link_from_email_body(body, upload_url)
    text = body.to_s.dup
    text = text.gsub(upload_url.to_s, "") if upload_url.present?
    text = text.gsub(Setting::LINK_PLACEHOLDER, "")
    text = text.gsub(/\s*pelo\s+(link|botão)\s+abaixo:?\s*/i, "\n")
    text = text.gsub(/\s*(use|acesse)\s+o\s+(link|botão)\s+abaixo:?\s*/i, "\n")
    text = text.gsub(/\s*clique no botão abaixo:?\s*/i, "\n")
    text = text.gsub(/\s*para enviar os arquivos,?\s*clique no botão abaixo:?\s*/i, "\n")
    text = text.gsub(/\s*caso o botão não funcione,?\s*utilize o link abaixo no navegador:?\s*/i, "\n")

    text.split("\n").reject { |line| link_only_line?(line) }.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end

  private

  def link_only_line?(line)
    stripped = line.strip
    return true if stripped.blank?

    stripped.match?(LINK_ONLY_LINE)
  end

  def highlight_email_body_text(text, client_name:, period_label: nil)
    escaped = ERB::Util.html_escape(text)
    strong = "strong style=\"color:#18181b;font-weight:600;\""

    if client_name.present?
      escaped_name = ERB::Util.html_escape(client_name)
      escaped = escaped.gsub(escaped_name, "<#{strong}>#{escaped_name}</strong>")
    end

    if period_label.present?
      escaped_period = ERB::Util.html_escape(period_label)
      escaped = escaped.gsub(escaped_period, "<#{strong}>#{escaped_period}</strong>")
    end

    escaped.html_safe
  end
end

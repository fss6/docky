module ApplicationHelper
  include AppConfirmModalHelper

  MARKDOWN_ALLOWED_TAGS = %w[
    p br strong em ul ol li h1 h2 h3 h4 table thead tbody tr th td a code pre blockquote
  ].freeze
  MARKDOWN_ALLOWED_ATTRIBUTES = %w[href].freeze

  def signup_disabled?
    Dokivo.signup_disabled?
  end

  # Atalho estável: /chat → ChatController → lista de conversas (primeira conta).
  def nav_chat_path
    chat_path
  end

  # Lista + thread do módulo chat: layout full-height no main (scroll só dentro do módulo).
  def chat_module_page?
    controller_name == "conversations" && %w[index show].include?(action_name)
  end

  # Tipografia das respostas do assistente (alinhada ao wiki).
  def chat_assistant_prose_classes
    [
      "chat-assistant-content",
      "prose prose-sm sm:prose-base prose-zinc max-w-none",
      "prose-headings:font-semibold prose-a:text-accent prose-code:text-sm"
    ].join(" ")
  end

  # HTML seguro a partir de Markdown (chat do assistente).
  def assistant_message_html(content)
    markdown_html(content)
  end

  def assistant_structured_html(message)
    return "".html_safe unless message.structured_components.any?

    Messages::AiResponseRenderer.render(message.structured_components)
  end

  # Wiki e outros conteúdos longos em Markdown.
  def wiki_page_content_html(markdown_content)
    return "" if markdown_content.blank?

    content_tag(:div, markdown_html(markdown_content), class: "wiki-markdown-content chat-assistant-content")
  end

  def markdown_html(content)
    return "" if content.blank?

    sanitize(
      Messages::RenderMarkdown.call(content),
      tags: MARKDOWN_ALLOWED_TAGS,
      attributes: MARKDOWN_ALLOWED_ATTRIBUTES
    )
  end

  # Ex.: maio/2026 → "Maio/2026" (URLs e params continuam YYYY-MM).
  def period_display_label(period)
    PeriodFormatting.display_label(period)
  end

  # Valor do flatpickr (dateFormat Y/m); o altInput exibe mês/ano por locale.
  def period_picker_value(period)
    PeriodFormatting.picker_value(period)
  end

  def toast_triggers_for(record: nil, notice: nil, alert: nil)
    safe_join([
      (render("shared/record_errors_toast", record: record) if record&.errors&.any?),
      (render("shared/toast_triggers", messages: notice, type: "success") if notice.present?),
      (render("shared/toast_triggers", messages: alert, type: "error") if alert.present?)
    ].compact)
  end

end

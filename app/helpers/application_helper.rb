module ApplicationHelper
  include AppConfirmModalHelper

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

  # Renderiza conteúdo Markdown como HTML seguro (via elemento com data-markdown).
  # A conversão acontece client-side via marked.js carregado no layout.
  def wiki_page_content_html(markdown_content)
    return "" if markdown_content.blank?

    content_tag(:div,
      markdown_content,
      data: { markdown: true },
      class: "wiki-markdown-content"
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

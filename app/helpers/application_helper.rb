module ApplicationHelper
  include AppConfirmModalHelper

  def bank_statement_amount_currency(amount)
    number_to_currency(amount, locale: :"pt-BR")
  end

  def bank_statement_transaction_type_label(transaction_type)
    I18n.t(
      "activerecord.enums.bank_statement.transaction_type.#{transaction_type}",
      default: transaction_type.to_s.titleize
    )
  end

  # Cor do valor nas tabelas de extrato: negativo vermelho, positivo verde.
  # Usa o tipo (crédito/débito) quando a quantia vem sempre positiva na BD.
  def bank_statement_amount_text_class(statement)
    amt = statement.amount.to_d
    signed = statement.credit? ? amt : -amt.abs

    if signed.negative?
      "text-red-600"
    elsif signed.positive?
      "text-emerald-700"
    else
      "text-zinc-900"
    end
  end

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

end

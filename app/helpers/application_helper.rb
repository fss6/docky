module ApplicationHelper
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

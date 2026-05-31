# frozen_string_literal: true

class LlmService
  CONTEXT_MAX_CHARS      = 12_000
  USER_CONTENT_MAX_CHARS = 12_000
  WIKI_MAX_CHARS         = 6_000
  DOCS_MAX_CHARS         = 6_000

  def self.stream(context:, history:, user_content:, &block)
    user_text    = user_content.to_s.strip.truncate(USER_CONTENT_MAX_CHARS, omission: "…")
    history_msgs = Array(history).map { |m| { role: m[:role].to_s, content: m[:content].to_s } }

    messages = [
      { role: "system", content: system_prompt(context) },
      *history_msgs,
      { role: "user", content: user_text }
    ]
    Openai::Chat.stream(messages: messages, &block)
  end

  # context pode ser uma String simples (legado) ou um Hash { wiki_chunks:, doc_chunks: }
  def self.system_prompt(context, markdown_block: Messages::MarkdownGuidelines::PROMPT_BLOCK)
    if context.is_a?(Hash)
      build_wiki_system_prompt(context, markdown_block: markdown_block)
    else
      build_plain_system_prompt(context.to_s, markdown_block: markdown_block)
    end
  end

  def self.smalltalk_system_prompt
    <<~PROMPT
      Você é o assistente Dokivo: um assistente de conversa dedicado a esta conta.

      O usuário mandou só uma saudação ou mensagem muito curta (sem pergunta ainda).
      Responda no mesmo idioma da mensagem, com tom caloroso e natural — como um assistente real cumprimentando e se colocando à disposição.

      Explique em 2–4 frases curtas como pode ajudar, por exemplo: responder perguntas com base nos documentos que a conta carregou, resumir trechos e localizar cláusulas ou dados. As fontes são exibidas à parte na interface; não mencione arquivo ou página no texto.
      Convide a fazer a primeira pergunta sobre os documentos.

      Não invente nomes de arquivos nem trechos. Não diga que "não encontrou" informação só porque foi uma saudação.
    PROMPT
  end

  private_class_method def self.build_wiki_system_prompt(context, markdown_block:)
    wiki_chunks = Array(context[:wiki_chunks])
    doc_chunks  = Array(context[:doc_chunks])
    if wiki_chunks.empty? && doc_chunks.empty?
      return smalltalk_system_prompt
    end

    wiki_text = wiki_chunks.map(&:content).join("\n\n").truncate(WIKI_MAX_CHARS)
    docs_text = doc_chunks.map.with_index do |r, i|
      info = r.source_info
      "--- Trecho #{i + 1} (#{info['file']} · p. #{info['page'] || '?'}) ---\n#{r.content}"
    end.join("\n\n").truncate(DOCS_MAX_CHARS)

    wiki_section = wiki_text.present? ? "=== CONHECIMENTO ACUMULADO (Wiki) ===\n#{wiki_text}" : ""
    docs_section = docs_text.present? ? "=== TRECHOS DOS DOCUMENTOS ORIGINAIS ===\n#{docs_text}" : ""
    full_context = [wiki_section, docs_section].reject(&:blank?).join("\n\n")

    <<~PROMPT
      Você é um assistente especializado em análise de documentos.

      Há mensagens anteriores nesta conversa. Use-as só para interpretar a pergunta atual
      (referências como "isso", "o item anterior", continuação do assunto). Não trate o
      histórico como fonte de fatos sobre os documentos.

      Trate o CONHECIMENTO ACUMULADO (Wiki) como informação já validada e consolidada.
      Trate os TRECHOS DOS DOCUMENTOS ORIGINAIS como evidência bruta de suporte.
      Se a resposta não estiver no contexto, diga explicitamente que não encontrou.
      #{Messages::CitationGuidelines::NO_INLINE_CITATIONS}

      #{markdown_block}

      #{full_context}
    PROMPT
  end

  private_class_method def self.build_plain_system_prompt(ctx, markdown_block:)
    ctx = ctx.strip
    return smalltalk_system_prompt if ctx.blank?

    ctx = ctx.truncate(CONTEXT_MAX_CHARS)
    <<~PROMPT
      Você é um assistente especializado em análise de documentos.

      Há mensagens anteriores nesta conversa. Use-as só para interpretar a pergunta atual
      (referências como "isso", "o item anterior", continuação do assunto). Não trate o
      histórico como fonte de fatos sobre os documentos.

      Para conteúdo factual sobre os arquivos, use exclusivamente os trechos abaixo.
      Se a resposta não estiver nos trechos, diga explicitamente que não encontrou.
      #{Messages::CitationGuidelines::NO_INLINE_CITATIONS}

      #{markdown_block}

      TRECHOS RELEVANTES:
      #{ctx}
    PROMPT
  end
end

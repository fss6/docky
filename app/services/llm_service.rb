# frozen_string_literal: true

class LlmService
  CONTEXT_MAX_CHARS = 12_000
  USER_CONTENT_MAX_CHARS = 12_000

  def self.stream(context:, history:, user_content:, &block)
    user_text = user_content.to_s.strip.truncate(USER_CONTENT_MAX_CHARS, omission: "…")
    history_msgs = Array(history).map { |m| { role: m[:role].to_s, content: m[:content].to_s } }

    messages = [
      { role: "system", content: system_prompt(context) },
      *history_msgs,
      { role: "user", content: user_text }
    ]
    Openai::Chat.stream(messages: messages, &block)
  end

  def self.system_prompt(context)
    ctx = context.to_s.truncate(CONTEXT_MAX_CHARS)
    <<~PROMPT
      Você é um assistente especializado em análise de documentos.

      Há mensagens anteriores nesta conversa. Use-as só para interpretar a pergunta atual
      (referências como "isso", "o item anterior", continuação do assunto). Não trate o
      histórico como fonte de fatos sobre os documentos.

      Para conteúdo factual sobre os arquivos, use exclusivamente os trechos abaixo.
      Se a resposta não estiver nos trechos, diga explicitamente que não encontrou.
      Sempre cite a fonte: nome do arquivo e número da página.

      TRECHOS RELEVANTES:
      #{ctx}
    PROMPT
  end
end

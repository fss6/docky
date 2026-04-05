# frozen_string_literal: true

class LlmService
  CONTEXT_MAX_CHARS = 12_000

  def self.stream(context:, history:, user_content:, &block)
    messages = [
      { role: "system", content: system_prompt(context) },
      *history.map { |m| { role: m[:role], content: m[:content].to_s } },
      { role: "user", content: user_content.to_s }
    ]
    Openai::Chat.stream(messages: messages, &block)
  end

  def self.system_prompt(context)
    ctx = context.to_s.truncate(CONTEXT_MAX_CHARS)
    <<~PROMPT
      Você é um assistente especializado em análise de documentos.
      Responda SOMENTE com base nos trechos fornecidos abaixo.
      Se a resposta não estiver nos trechos, diga explicitamente que não encontrou.
      Sempre cite a fonte: nome do arquivo e número da página.

      TRECHOS RELEVANTES:
      #{ctx}
    PROMPT
  end
end

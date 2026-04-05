# frozen_string_literal: true

module Conversations
  class TitleGenerator
    SYSTEM_PROMPT = <<~TEXT.squish.freeze
      Você gera títulos curtos para conversas de chat.
      Responda APENAS com o título, sem aspas, sem dois-pontos no início, sem prefixos como "Conversa sobre".
      No máximo 8 palavras. Use o mesmo idioma da mensagem do usuário.
    TEXT

    def self.generate(user_content)
      text = user_content.to_s.strip
      return nil if text.blank?
      return nil if Rag::QueryIntent.skip_title_generation?(text)

      raw = Openai::Completion.call(
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: "Primeira mensagem do usuário:\n#{text.truncate(4_000)}" }
        ],
        max_tokens: 48,
        temperature: 0.35
      )
      sanitize(raw)
    end

    def self.sanitize(raw)
      t = raw.to_s.strip
      t = t.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
      t = t.gsub(/\s+/, " ").strip
      t = t.truncate(Conversation::TITLE_MAX_LENGTH, omission: "")
      t.presence
    end
  end
end

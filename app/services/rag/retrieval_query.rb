# frozen_string_literal: true

module Rag
  # Monta o texto enviado ao embedding da recuperação (RAG).
  # Perguntas de follow-up ("deste artigo", "esses pontos") sozinhas não batem nos chunks;
  # incluímos as últimas perguntas do usuário na mesma conversa para manter o assunto.
  class RetrievalQuery
    PRIOR_USER_COUNT = 4
    MAX_TOTAL_CHARS = 7500
    MAX_CURRENT_CHARS = 2500

    def self.build(conversation:, user_message:)
      current = user_message.content.to_s.strip.truncate(MAX_CURRENT_CHARS, omission: "…")
      return current if current.blank?

      prior_msgs = conversation.messages
        .where(role: "user")
        .where("id < ?", user_message.id)
        .order(:id)
        .last(PRIOR_USER_COUNT)
        .map { |m| m.content.to_s.strip }
        .reject(&:blank?)

      compose(prior_msgs, current)
    end

    def self.compose(prior_strings, current)
      cur = current.to_s.strip
      return cur if cur.blank?

      prior_joined = Array(prior_strings).map(&:strip).reject(&:blank?).join("\n\n")
      return cur if prior_joined.blank?

      overhead = 4
      budget = MAX_TOTAL_CHARS - cur.length - overhead
      if budget.positive?
        prior_joined = prior_joined.truncate(budget, omission: "…")
        "#{prior_joined}\n\n#{cur}"
      else
        cur.truncate(MAX_TOTAL_CHARS, omission: "…")
      end
    end
  end
end

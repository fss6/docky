# frozen_string_literal: true

# Janela de mensagens enviada ao modelo: evita conversas longas estourarem contexto/custo.
class LlmConversationHistory
  ALLOWED_ROLES = %w[user assistant].freeze

  # Até ~12 trocas (24 mensagens); corta as mais antigas primeiro.
  MAX_MESSAGES = 24

  # Teto global do histórico (~2,5k tokens estimados); remove mensagens antigas até caber.
  MAX_TOTAL_CHARS = 10_000

  # Evita uma única resposta gigante dominar o orçamento.
  MAX_MESSAGE_CHARS = 4_000

  def self.for_conversation(conversation, before_message_id:)
    rows = conversation.messages
      .where("id < ?", before_message_id)
      .order(:id)
      .pluck(:role, :content)

    messages = rows.map { |role, content| { role: role.to_s, content: content.to_s } }
    trim(messages)
  end

  def self.trim(messages)
    normalized = messages.filter_map do |m|
      role = m[:role].to_s
      next unless ALLOWED_ROLES.include?(role)

      text = m[:content].to_s.strip
      next if text.blank?

      text = text.truncate(MAX_MESSAGE_CHARS, omission: "…")
      { role: role, content: text }
    end

    window = normalized.last(MAX_MESSAGES)
    shrink_to_char_budget!(window)
    window
  end

  def self.shrink_to_char_budget!(window)
    while window.size > 1 && total_chars(window) > MAX_TOTAL_CHARS
      window.shift
    end

    return unless window.one? && total_chars(window) > MAX_TOTAL_CHARS

    only = window.first
    window[0] = { role: only[:role], content: only[:content].truncate(MAX_TOTAL_CHARS, omission: "…") }
  end

  def self.total_chars(messages)
    messages.sum { |m| m[:content].to_s.length }
  end
  private_class_method :total_chars
end

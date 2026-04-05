# frozen_string_literal: true

class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation, touch: true

  validates :role, inclusion: { in: ROLES }

  # Opcional por mensagem: RAG só neste documento (ex.: atalho a partir da página do arquivo).
  def focus_document_id
    m = metadata
    return nil unless m.is_a?(Hash)

    v = m["focus_document_id"] || m[:focus_document_id]
    v.present? ? v.to_i : nil
  end

  def assistant?
    role == "assistant"
  end

  def user?
    role == "user"
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  content         :text
#  metadata        :jsonb            not null
#  role            :string
#  sources         :jsonb
#  streaming       :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_messages_on_conversation_id  (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#
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

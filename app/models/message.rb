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

  def structured_components
    return [] unless metadata.is_a?(Hash)

    Array(metadata["components"]).filter_map do |component|
      next unless component.is_a?(Hash)
      next if component["type"].blank?
      next unless component["data"].is_a?(Hash)

      component
    end
  end

  def structured_response?
    structured_components.any?
  end

  def structured_tables
    from_components = structured_components.filter_map do |component|
      next unless component["type"] == "table"

      data = component["data"]
      headers = Array(data["headers"]).map(&:to_s).reject(&:blank?)
      rows = Array(data["rows"]).map { |row| Array(row).map(&:to_s) }
      next if headers.blank? || rows.blank?

      {
        "title" => data["title"].to_s.presence,
        "columns" => headers,
        "rows" => rows
      }
    end
    return from_components if from_components.any?

    return [] unless metadata.is_a?(Hash)

    Array(metadata["tables"]).filter_map do |table|
      next unless table.is_a?(Hash)

      columns = Array(table["columns"]).map(&:to_s).reject(&:blank?)
      rows = Array(table["rows"]).map { |row| Array(row).map(&:to_s) }
      next if columns.blank? || rows.blank?

      table.merge("columns" => columns, "rows" => rows)
    end
  end

  def context_sources
    return [] unless metadata.is_a?(Hash)

    Array(metadata["context_sources"])
  end

  def context_sources?
    context_sources.any?
  end

  def answer_text_for_sources
    return content.to_s if structured_components.blank?

    Messages::AiComponents::Registry.plain_text_answer(
      summary: metadata.is_a?(Hash) ? metadata["summary"].to_s : "",
      components: structured_components
    )
  end
end

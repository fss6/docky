# frozen_string_literal: true

class EmbeddingRecord < ApplicationRecord
  has_neighbors :embedding

  belongs_to :account
  belongs_to :document, optional: true
  belongs_to :recordable, polymorphic: true

  scope :ordered_for_display, lambda {
    order(
      Arel.sql("(metadata->>'page')::integer NULLS LAST"),
      Arel.sql("(metadata->>'chunk_index')::integer NULLS LAST")
    )
  }

  scope :pending_embedding, lambda {
    where(embedding: nil).where.not(content: nil).where.not(content: "")
  }

  validate :document_id_matches_document_recordable

  def page_number
    metadata&.fetch("page", nil)
  end

  def chunk_index
    metadata&.fetch("chunk_index", nil)
  end

  def source_info
    fname = document&.file&.attached? ? document.file.filename.to_s : "documento"
    { "file" => fname, "page" => page_number, "chunk_id" => id }
  end

  private

  def document_id_matches_document_recordable
    return unless recordable.is_a?(Document)

    expected = recordable.id
    if document_id.present? && document_id != expected
      errors.add(:document_id, "deve ser o mesmo id do recordable (documento)")
    end
  end
end

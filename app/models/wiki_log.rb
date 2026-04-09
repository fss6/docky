# frozen_string_literal: true

class WikiLog < ApplicationRecord
  belongs_to :account

  OPERATIONS = %w[ingest query lint].freeze

  validates :operation, inclusion: { in: OPERATIONS }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_operation, ->(op) { where(operation: op) }
end

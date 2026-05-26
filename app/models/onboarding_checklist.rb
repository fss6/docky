# frozen_string_literal: true

class OnboardingChecklist < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :client
  has_many :items, class_name: "OnboardingChecklistItem", dependent: :destroy, inverse_of: :onboarding_checklist

  enum :status, {
    in_progress: "in_progress",
    completed: "completed"
  }, default: :in_progress

  validates :onboarding_kind, presence: true
  validates :started_at, presence: true
  validates :client_id, uniqueness: true

  scope :stale, ->(days = 30) { in_progress.where(started_at: ...days.days.ago) }

  def all_items_complete?
    items.exists? && items.where.not(state: %w[received validated]).none?
  end
end

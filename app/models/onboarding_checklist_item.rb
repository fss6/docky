# frozen_string_literal: true

class OnboardingChecklistItem < ApplicationRecord
  belongs_to :onboarding_checklist, inverse_of: :items
  belongs_to :last_document, class_name: "Document", optional: true
  belongs_to :validated_by_user, class_name: "User", optional: true

  enum :state, {
    pending: "pending",
    received: "received",
    validated: "validated"
  }, default: :pending

  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  def complete?
    received? || validated?
  end

  def mark_received!(document: nil, user: nil)
    attrs = { state: :received, received_at: Time.current }
    attrs[:last_document] = document if document
    if user && document.nil?
      attrs[:state] = :validated
      attrs[:validated_by_user] = user
      attrs[:validated_at] = Time.current
    end
    update!(attrs)
  end

  def mark_pending!
    update!(
      state: :pending,
      last_document: nil,
      validated_by_user: nil,
      validated_at: nil,
      received_at: nil
    )
  end
end

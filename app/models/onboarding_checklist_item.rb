# frozen_string_literal: true

# == Schema Information
#
# Table name: onboarding_checklist_items
#
#  id                      :bigint           not null, primary key
#  help_text               :text
#  name                    :string           not null
#  position                :integer          default(0), not null
#  received_at             :datetime
#  state                   :string           default("pending"), not null
#  validated_at            :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  last_document_id        :bigint
#  onboarding_checklist_id :bigint           not null
#  validated_by_user_id    :bigint
#
# Indexes
#
#  index_onboarding_checklist_items_on_last_document_id         (last_document_id)
#  index_onboarding_checklist_items_on_onboarding_checklist_id  (onboarding_checklist_id)
#
# Foreign Keys
#
#  fk_rails_...  (last_document_id => documents.id)
#  fk_rails_...  (onboarding_checklist_id => onboarding_checklists.id)
#  fk_rails_...  (validated_by_user_id => users.id)
#
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

# frozen_string_literal: true

# == Schema Information
#
# Table name: onboarding_checklists
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  onboarding_kind :string           not null
#  started_at      :datetime         not null
#  status          :string           default("in_progress"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  client_id       :bigint           not null
#
# Indexes
#
#  index_onboarding_checklists_on_account_id  (account_id)
#  index_onboarding_checklists_on_client_id   (client_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#
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

  def all_items_complete?
    items.exists? && items.where.not(state: %w[received validated]).none?
  end
end

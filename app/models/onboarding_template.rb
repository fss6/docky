# frozen_string_literal: true

class OnboardingTemplate < ApplicationRecord
  acts_as_tenant(:account)

  KINDS = %w[mei new_company migration].freeze

  belongs_to :account
  has_many :items, class_name: "OnboardingTemplateItem", dependent: :destroy, inverse_of: :onboarding_template

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :kind, uniqueness: { scope: :account_id }

  scope :ordered, -> { order(:position, :id) }

  def self.kind_for_onboarding_kind(onboarding_kind)
    case onboarding_kind.to_s
    when "migration" then "migration"
    when "new_client" then "new_company"
    else "new_company"
    end
  end
end

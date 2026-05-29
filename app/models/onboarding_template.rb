# frozen_string_literal: true

# == Schema Information
#
# Table name: onboarding_templates
#
#  id         :bigint           not null, primary key
#  kind       :string           not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_onboarding_templates_on_account_id           (account_id)
#  index_onboarding_templates_on_account_id_and_kind  (account_id,kind) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class OnboardingTemplate < ApplicationRecord
  acts_as_tenant(:account)

  KINDS = %w[mei new_company migration].freeze

  belongs_to :account
  has_many :items, class_name: "OnboardingTemplateItem", dependent: :destroy, inverse_of: :onboarding_template
  accepts_nested_attributes_for :items,
                                allow_destroy: true,
                                reject_if: ->(attributes) { attributes["name"].blank? && attributes["id"].blank? }

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

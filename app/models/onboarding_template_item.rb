# frozen_string_literal: true

# == Schema Information
#
# Table name: onboarding_template_items
#
#  id                     :bigint           not null, primary key
#  help_text              :text
#  name                   :string           not null
#  position               :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  onboarding_template_id :bigint           not null
#
# Indexes
#
#  index_onboarding_template_items_on_template_and_position  (onboarding_template_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (onboarding_template_id => onboarding_templates.id)
#
class OnboardingTemplateItem < ApplicationRecord
  belongs_to :onboarding_template, inverse_of: :items

  validates :name, presence: true
  validates :position, numericality: { only_integer: true }

  scope :ordered, -> { order(:position, :id) }
end

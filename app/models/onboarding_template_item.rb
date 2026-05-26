# frozen_string_literal: true

class OnboardingTemplateItem < ApplicationRecord
  belongs_to :onboarding_template, inverse_of: :items

  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }
end

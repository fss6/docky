# frozen_string_literal: true

# == Schema Information
#
# Table name: onboarding_templates
#
#  id          :bigint           not null, primary key
#  description :text
#  kind        :string           not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  system      :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
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

  DEFAULT_KINDS = %w[mei new_company migration].freeze
  DESCRIPTION_MAX_LENGTH = 500

  belongs_to :account
  has_many :items, class_name: "OnboardingTemplateItem", dependent: :destroy, inverse_of: :onboarding_template
  has_many :clients, dependent: :restrict_with_error
  has_many :onboarding_checklists, dependent: :restrict_with_error

  accepts_nested_attributes_for :items,
                                allow_destroy: true,
                                reject_if: ->(attributes) { attributes["name"].blank? && attributes["id"].blank? }

  before_validation :assign_kind_from_name, on: :create, if: -> { kind.blank? }
  before_validation :assign_position, on: :create

  validates :name, presence: true
  validates :kind, presence: true, uniqueness: { scope: :account_id }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  scope :ordered, -> { order(:position, :id) }

  def self.default_for_client_creation(account = ActsAsTenant.current_tenant)
    scope = account.onboarding_templates.ordered
    scope.find_by(kind: "new_company") || scope.first
  end

  def help_text_for_select
    description.presence || "#{items.size} #{items.size == 1 ? 'item' : 'itens'}"
  end

  def destroy_confirm_message
    if clients.exists?
      I18n.t("settings.onboarding_templates.destroy_confirm.in_use", name: name)
    elsif system?
      I18n.t("settings.onboarding_templates.destroy_confirm.system", name: name)
    else
      I18n.t("settings.onboarding_templates.destroy_confirm.custom", name: name)
    end
  end

  def destroy_modal_variant
    if clients.exists?
      :in_use
    elsif system?
      :system
    else
      :custom
    end
  end

  def destroy_modal_body_prefix
    I18n.t("settings.onboarding_templates.destroy_modal.#{destroy_modal_variant}.body_prefix")
  end

  def destroy_modal_body_suffix
    I18n.t("settings.onboarding_templates.destroy_modal.#{destroy_modal_variant}.body_suffix")
  end

  private

  def assign_kind_from_name
    self.kind = unique_kind_from(name)
  end

  def assign_position
    self.position = account.onboarding_templates.maximum(:position).to_i + 1
  end

  def unique_kind_from(label)
    base = label.to_s.parameterize(separator: "_")
    base = "template" if base.blank?

    candidate = base
    suffix = 2
    scope = account.onboarding_templates
    while scope.exists?(kind: candidate)
      candidate = "#{base}_#{suffix}"
      suffix += 1
    end

    candidate
  end
end

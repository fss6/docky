# == Schema Information
#
# Table name: accounts
#
#  id          :bigint           not null, primary key
#  active      :boolean
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  plan_id     :bigint           not null
#
# Indexes
#
#  index_accounts_on_plan_id  (plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (plan_id => plans.id)
#
class Account < ApplicationRecord
  belongs_to :plan

  has_many :users, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_one :setting, dependent: :destroy
  has_many :wiki_pages, dependent: :destroy
  has_many :wiki_logs, dependent: :destroy
  has_one :wiki_schema, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :client_checklist_items, dependent: :destroy
  has_many :competency_checklists, class_name: "Period", dependent: :destroy

  def periods
    competency_checklists
  end
  has_many :competency_checklist_items, through: :competency_checklists, source: :items
  has_many :institutions, dependent: :destroy
  has_many :audit_events, dependent: :destroy
  has_many :onboarding_templates, dependent: :destroy
  has_many :permission_grants, class_name: "AccountPermissionGrant", dependent: :destroy

  after_create :create_default_setting!
  after_create :seed_default_permission_grants!
  after_create :seed_default_institutions!
  after_create :seed_onboarding_templates!, unless: :skip_onboarding_template_seed?

  def generate_tags_automatically?
    setting&.generate_tags_automatically == true
  end

  private

  def create_default_setting!
    create_setting! unless setting
  end

  def seed_default_permission_grants!
    Permissions::SeedDefaults.call(account: self)
  end

  def seed_default_institutions!
    Institution.seed_defaults_for!(self)
  end

  def seed_onboarding_templates!
    Onboarding::SeedDefaultTemplates.call(account: self)
  end

  def skip_onboarding_template_seed?
    Rails.env.test?
  end
end

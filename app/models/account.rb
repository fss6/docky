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
  has_many :competency_checklists, dependent: :destroy
  has_many :competency_checklist_items, through: :competency_checklists, source: :items
  has_many :bank_statement_imports, dependent: :destroy
  has_many :bank_statements, dependent: :destroy
  has_many :institutions, dependent: :destroy
  has_many :audit_events, dependent: :destroy

  after_create :create_default_setting!
  after_create :seed_default_institutions!

  def generate_tags_automatically?
    setting&.generate_tags_automatically == true
  end

  private

  def create_default_setting!
    create_setting! unless setting
  end

  def seed_default_institutions!
    Institution.seed_defaults_for!(self)
  end
end

# frozen_string_literal: true

class Client < ApplicationRecord
  acts_as_tenant(:account)

  enum :status, {
    onboarding: "onboarding",
    active: "active"
  }, default: :active

  ONBOARDING_KINDS = %w[new_client migration skipped].freeze

  has_many :folders, dependent: :nullify
  has_many :client_checklist_items, dependent: :destroy
  has_many :competency_checklists, class_name: "Period", dependent: :destroy
  has_one :onboarding_checklist, dependent: :destroy

  def periods
    competency_checklists
  end
  has_many :upload_invites, dependent: :destroy
  has_many :collection_documents, class_name: "Document", dependent: :nullify
  has_many :bank_statement_imports, dependent: :destroy
  has_many :bank_statements, dependent: :destroy

  normalizes :tax_id, with: ->(v) { v.to_s.strip.presence }
  normalizes :name, with: ->(v) { v.to_s.strip }
  normalizes :email, with: ->(v) { v.to_s.strip.presence }
  normalizes :phone, with: ->(v) { v.to_s.strip.presence }

  validates :name, presence: true
  validates :monthly_deadline_day, inclusion: { in: 1..28 }
  validates :tax_id, uniqueness: { scope: :account_id }, allow_blank: true
  validates :onboarding_kind, inclusion: { in: ONBOARDING_KINDS }, allow_nil: true

  scope :onboarding_stale, ->(days = 30) {
    onboarding.joins(:onboarding_checklist).merge(OnboardingChecklist.stale(days))
  }

  def onboarding_in_progress?
    onboarding? && onboarding_checklist&.in_progress?
  end
end

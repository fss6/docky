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

  scope :search_q, ->(q) {
    term = q.to_s.strip
    next all if term.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    digits = digits_only(term)
    if digits.present?
      where(
        "clients.name ILIKE :like OR clients.email ILIKE :like OR regexp_replace(clients.tax_id, '[^0-9]', '', 'g') LIKE :digits",
        like: like,
        digits: "%#{ActiveRecord::Base.sanitize_sql_like(digits)}%"
      )
    else
      where("clients.name ILIKE :like OR clients.email ILIKE :like", like: like)
    end
  }

  scope :with_status, ->(status) {
    key = status.to_s
    next all unless statuses.key?(key)

    where(status: key)
  }

  scope :matching_name, ->(name) {
    term = name.to_s.strip
    next all if term.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    where("clients.name ILIKE ?", like)
  }

  scope :matching_email, ->(email) {
    term = email.to_s.strip
    next all if term.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    where("clients.email ILIKE ?", like)
  }

  scope :matching_tax_id, ->(raw) {
    digits = digits_only(raw)
    next all if digits.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(digits)}%"
    where("regexp_replace(clients.tax_id, '[^0-9]', '', 'g') LIKE ?", like)
  }

  def self.filtered_by_index_params(params)
    scope = all
    scope = scope.search_q(params[:q]) if params[:q].present?
    scope = scope.with_status(params[:status]) if params[:status].present?
    scope = scope.matching_name(params[:name]) if params[:name].present?
    scope = scope.matching_email(params[:email]) if params[:email].present?
    scope = scope.matching_tax_id(params[:tax_id]) if params[:tax_id].present?
    scope
  end

  def self.digits_only(str)
    str.to_s.gsub(/\D/, "")
  end

  def onboarding_in_progress?
    onboarding? && onboarding_checklist&.in_progress?
  end
end

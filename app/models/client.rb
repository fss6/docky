# frozen_string_literal: true

class Client < ApplicationRecord
  acts_as_tenant(:account)

  enum :status, {
    onboarding: "onboarding",
    active: "active"
  }, default: :active

  ONBOARDING_KINDS = %w[new_client migration skipped].freeze
  VISIBILITIES = %w[active archived all].freeze

  belongs_to :archived_by_user, class_name: "User", optional: true

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

  scope :kept, -> { where(archived_at: nil) }
  scope :archived_records, -> { where.not(archived_at: nil) }

  scope :with_visibility, ->(visibility) {
    case visibility.to_s
    when "archived"
      archived_records
    when "all"
      all
    else
      kept
    end
  }

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

  def self.filtered_by_index_params(params, base_scope: all)
    scope = base_scope.with_visibility(params[:visibility])
    scope = scope.search_q(params[:q]) if params[:q].present?
    scope = scope.with_status(params[:status]) if params[:status].present?
    scope
  end

  def self.digits_only(str)
    str.to_s.gsub(/\D/, "")
  end

  def archived?
    archived_at.present?
  end

  def kept?
    !archived?
  end

  def onboarding_in_progress?
    onboarding? && onboarding_checklist&.in_progress?
  end
end

# frozen_string_literal: true

class Period < ApplicationRecord
  self.table_name = "competency_checklists"

  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :client
  belongs_to :closed_by_user, class_name: "User", optional: true

  has_many :items,
           class_name: "CompetencyChecklistItem",
           foreign_key: :competency_checklist_id,
           dependent: :destroy,
           inverse_of: :competency_checklist
  has_many :documents, dependent: :nullify

  enum :status, { open: "open", closed: "closed" }, default: :open

  before_validation :normalize_period!
  before_validation :ensure_opened_at, on: :create

  validates :period, presence: true
  validates :period, uniqueness: { scope: %i[account_id client_id] }
  validates :opened_at, presence: true

  scope :open_periods, -> { where(status: :open) }
  scope :for_month, ->(date) { where(period: date.to_date.beginning_of_month) }

  def closed?
    status == "closed"
  end

  def period_param
    period.strftime("%Y-%m")
  end

  private

  def normalize_period!
    return if period.blank?

    self.period = period.to_date.beginning_of_month
  end

  def ensure_opened_at
    self.opened_at ||= Time.current
  end
end

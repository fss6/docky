# frozen_string_literal: true

# == Schema Information
#
# Table name: competency_checklists
#
#  id                :bigint           not null, primary key
#  closed_at         :datetime
#  opened_at         :datetime         not null
#  period            :date             not null
#  status            :string           default("open"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  client_id         :bigint           not null
#  closed_by_user_id :bigint
#
# Indexes
#
#  idx_on_account_id_client_id_period_7cc7b2bb99     (account_id,client_id,period) UNIQUE
#  index_competency_checklists_on_account_id         (account_id)
#  index_competency_checklists_on_client_id          (client_id)
#  index_competency_checklists_on_closed_by_user_id  (closed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (closed_by_user_id => users.id)
#
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
  scope :with_pending_receipts, lambda {
    open_periods
      .joins(:items)
      .where(competency_checklist_items: { state: "pending", last_document_id: nil })
      .distinct
  }

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

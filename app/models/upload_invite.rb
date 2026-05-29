# frozen_string_literal: true

# == Schema Information
#
# Table name: upload_invites
#
#  id                 :bigint           not null, primary key
#  access_count       :integer          default(0), not null
#  expires_at         :datetime
#  period             :date
#  purpose            :string           default("monthly"), not null
#  revoked_at         :datetime
#  token              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  client_id          :bigint           not null
#  created_by_user_id :bigint
#
# Indexes
#
#  index_upload_invites_on_account_id             (account_id)
#  index_upload_invites_on_client_id              (client_id)
#  index_upload_invites_on_client_period_created  (client_id,period,created_at)
#  index_upload_invites_on_client_purpose_active  (client_id,purpose) WHERE (revoked_at IS NULL)
#  index_upload_invites_on_created_by_user_id     (created_by_user_id)
#  index_upload_invites_on_token                  (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (created_by_user_id => users.id)
#
class UploadInvite < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :client
  belongs_to :created_by_user, class_name: "User", optional: true

  enum :purpose, {
    monthly: "monthly",
    onboarding: "onboarding"
  }, default: :monthly, prefix: true

  validates :token, presence: true, uniqueness: true
  validates :period, presence: true, if: :purpose_monthly?

  before_validation :normalize_period!
  before_validation :ensure_token, on: :create

  scope :for_period, ->(period) { where(period: period.beginning_of_month.to_date) }
  scope :for_onboarding, -> { purpose_onboarding }
  scope :newest_first, -> { order(created_at: :desc) }

  def onboarding?
    purpose_onboarding?
  end

  def self.generate_token
    SecureRandom.urlsafe_base64(24)
  end

  def active?
    revoked_at.blank? && !expired?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def status_label
    return "Revogado" if revoked_at.present?
    return "Expirado" if expired?

    "Ativo"
  end

  def masked_token
    return "—" if token.blank?

    "#{token.first(6)}…#{token.last(4)}"
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def record_access!
    increment!(:access_count)
  end

  private

  def normalize_period!
    return if purpose_onboarding?

    self.period = period.to_date.beginning_of_month if period.present?
  end

  def ensure_token
    self.token = self.class.generate_token if token.blank?
  end
end

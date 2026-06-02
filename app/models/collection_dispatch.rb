# frozen_string_literal: true

# == Schema Information
#
# Table name: collection_dispatches
#
#  id                  :bigint           not null, primary key
#  channel             :string           not null
#  metadata            :jsonb            not null
#  rendered_body       :text
#  rendered_subject    :string
#  sent_at             :datetime
#  skip_reason         :string
#  status              :string           default("scheduled"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  client_id           :bigint           not null
#  collection_step_id  :bigint           not null
#  period_id           :bigint           not null
#  provider_message_id :string
#
# Indexes
#
#  idx_on_account_id_status_created_at_e8df138900      (account_id,status,created_at)
#  index_collection_dispatches_on_account_id           (account_id)
#  index_collection_dispatches_on_client_id            (client_id)
#  index_collection_dispatches_on_collection_step_id   (collection_step_id)
#  index_collection_dispatches_on_period_id            (period_id)
#  index_collection_dispatches_on_provider_message_id  (provider_message_id)
#  index_collection_dispatches_unique_per_cycle        (client_id,period_id,collection_step_id,channel) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (collection_step_id => collection_steps.id)
#  fk_rails_...  (period_id => competency_checklists.id)
#
class CollectionDispatch < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :client
  belongs_to :period, class_name: "Period", inverse_of: false
  belongs_to :collection_step
  has_many :delivery_events, class_name: "CollectionDeliveryEvent", dependent: :destroy

  enum :channel, {
    email: "email",
    whatsapp: "whatsapp",
    internal: "internal"
  }, prefix: true

  enum :status, {
    scheduled: "scheduled",
    sent: "sent",
    failed: "failed",
    skipped: "skipped"
  }, default: :scheduled, prefix: true

  validates :channel, presence: true
  validates :status, presence: true

  scope :sent_in_month, ->(month) {
    start_at = month.beginning_of_month.beginning_of_day
    end_at = month.end_of_month.end_of_day
    status_sent.where(sent_at: start_at..end_at)
  }

  def mark_sent!(provider_message_id: nil, at: Time.current)
    update!(
      status: :sent,
      provider_message_id: provider_message_id,
      sent_at: at
    )
  end

  def mark_failed!(reason:)
    update!(status: :failed, skip_reason: reason)
  end

  def mark_skipped!(reason:)
    update!(status: :skipped, skip_reason: reason)
  end
end

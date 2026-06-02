# frozen_string_literal: true

# == Schema Information
#
# Table name: collection_steps
#
#  id                     :bigint           not null, primary key
#  email_body_template    :text
#  email_enabled          :boolean          default(FALSE), not null
#  email_subject_template :string
#  kind                   :string           default("client_reminder"), not null
#  name                   :string           not null
#  offset_days            :integer          not null
#  position               :integer          default(0), not null
#  whatsapp_body_template :text
#  whatsapp_enabled       :boolean          default(FALSE), not null
#  whatsapp_template_name :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#
# Indexes
#
#  index_collection_steps_on_account_id                  (account_id)
#  index_collection_steps_on_account_id_and_offset_days  (account_id,offset_days) UNIQUE
#  index_collection_steps_on_account_id_and_position     (account_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class CollectionStep < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  has_many :collection_dispatches, dependent: :restrict_with_error

  enum :kind, {
    client_reminder: "client_reminder",
    internal_alert: "internal_alert"
  }, default: :client_reminder, prefix: true

  validates :name, presence: true
  validates :offset_days, uniqueness: { scope: :account_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :offset_days) }

  def channels_enabled
    channels = []
    channels << :email if email_enabled?
    channels << :whatsapp if whatsapp_enabled? && kind_client_reminder?
    channels << :internal if email_enabled? && kind_internal_alert?
    channels
  end
end

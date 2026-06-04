# frozen_string_literal: true

# == Schema Information
#
# Table name: collection_settings
#
#  id                              :bigint           not null, primary key
#  enabled                         :boolean          default(FALSE), not null
#  max_messages_per_client_per_day :integer          default(1), not null
#  quiet_hours_end                 :time             default(2000-01-01 17:00:00.000000000 -02 -02:00), not null
#  quiet_hours_start               :time             default(2000-01-01 06:00:00.000000000 -02 -02:00), not null
#  timezone                        :string           default("America/Sao_Paulo"), not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  account_id                      :bigint           not null
#
# Indexes
#
#  index_collection_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class CollectionSetting < ApplicationRecord
  MAX_MESSAGES_PER_CLIENT_PER_CHANNEL = 1

  acts_as_tenant(:account)

  belongs_to :account

  validates :max_messages_per_client_per_day, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :timezone, presence: true

  after_create :seed_default_steps!

  def self.ensure_for!(account)
    account.collection_setting || account.create_collection_setting!
  end

  def quiet_hours_range
    quiet_hours_start..quiet_hours_end
  end

  private

  def seed_default_steps!
    Collection::SeedDefaultSteps.call(account: account)
  end
end

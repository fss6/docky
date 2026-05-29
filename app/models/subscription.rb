# == Schema Information
#
# Table name: subscriptions
#
#  id                 :bigint           not null, primary key
#  canceled_at        :datetime
#  current_period_end :datetime
#  status             :string
#  trial_ends_at      :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  plan_id            :bigint           not null
#
# Indexes
#
#  index_subscriptions_on_account_id  (account_id)
#  index_subscriptions_on_plan_id     (plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (plan_id => plans.id)
#
class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :plan

  enum :status, {
    trialing: 'trialing',
    active: 'active',
    past_due: 'past_due',
    unpaid: 'unpaid',
    canceled: 'canceled',
    expired: 'expired'
  }

  def active?
    %w[trialing active].include?(status)
  end

  def blocked?
    %w[unpaid expired].include?(status)
  end

end

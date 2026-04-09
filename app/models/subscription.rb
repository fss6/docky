class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :plan

  enum :status, {
    pending: "pending",
    trialing: 'trialing',
    active: 'active',
    past_due: 'past_due',
    unpaid: 'unpaid',
    canceled: 'canceled',
    expired: 'expired',
    incomplete: "incomplete"
  }

  def active?
    %w[trialing active].include?(status)
  end

  def blocked?
    %w[pending unpaid expired past_due incomplete].include?(status)
  end

end

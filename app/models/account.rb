class Account < ApplicationRecord
  belongs_to :plan

  has_many :users, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_one :setting, dependent: :destroy

  enum :billing_status, {
    pending: "pending",
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    incomplete: "incomplete"
  }, prefix: true

  after_create :create_default_setting!

  def generate_tags_automatically?
    setting&.generate_tags_automatically == true
  end

  def billing_access_granted?
    billing_status_active? || billing_status_trialing?
  end

  private

  def create_default_setting!
    create_setting! unless setting
  end
end

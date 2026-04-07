class Account < ApplicationRecord
  belongs_to :plan

  has_many :users, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_one :setting, dependent: :destroy

  after_create :create_default_setting!

  def generate_tags_automatically?
    setting&.generate_tags_automatically == true
  end

  private

  def create_default_setting!
    create_setting! unless setting
  end
end

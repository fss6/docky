# frozen_string_literal: true

class Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :account

  has_many :messages, dependent: :destroy

  validates :title, length: { maximum: 255 }, allow_blank: true
end

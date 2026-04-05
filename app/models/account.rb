class Account < ApplicationRecord
  belongs_to :plan

  has_many :users, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :conversations, dependent: :destroy
end

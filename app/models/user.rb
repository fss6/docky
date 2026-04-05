class User < ApplicationRecord
  belongs_to :account

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  belongs_to :account
end

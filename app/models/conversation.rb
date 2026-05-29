# frozen_string_literal: true

# == Schema Information
#
# Table name: conversations
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_conversations_on_account_id  (account_id)
#  index_conversations_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class Conversation < ApplicationRecord
  acts_as_tenant(:account)
  DEFAULT_TITLE = "Nova conversa"
  TITLE_MAX_LENGTH = 255

  belongs_to :user

  has_many :messages, dependent: :destroy

  validates :title, length: { maximum: TITLE_MAX_LENGTH }, allow_blank: true

  def default_title?
    title.blank? || title == DEFAULT_TITLE
  end
end

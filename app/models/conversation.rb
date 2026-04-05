# frozen_string_literal: true

class Conversation < ApplicationRecord
  DEFAULT_TITLE = "Nova conversa"
  TITLE_MAX_LENGTH = 255

  belongs_to :user
  belongs_to :account

  has_many :messages, dependent: :destroy

  validates :title, length: { maximum: TITLE_MAX_LENGTH }, allow_blank: true

  def default_title?
    title.blank? || title == DEFAULT_TITLE
  end
end

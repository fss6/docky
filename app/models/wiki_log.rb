# frozen_string_literal: true

# == Schema Information
#
# Table name: wiki_logs
#
#  id           :bigint           not null, primary key
#  details      :text
#  operation    :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  document_id  :integer
#  wiki_page_id :integer
#
# Indexes
#
#  index_wiki_logs_on_account_id                 (account_id)
#  index_wiki_logs_on_account_id_and_created_at  (account_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class WikiLog < ApplicationRecord
  belongs_to :account

  OPERATIONS = %w[ingest query lint].freeze

  validates :operation, inclusion: { in: OPERATIONS }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_operation, ->(op) { where(operation: op) }
end

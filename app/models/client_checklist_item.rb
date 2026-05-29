# == Schema Information
#
# Table name: client_checklist_items
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  match_terms :jsonb            not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  client_id   :bigint           not null
#
# Indexes
#
#  idx_on_account_id_client_id_active_80dda41374    (account_id,client_id,active)
#  idx_on_account_id_client_id_position_7f36bb5353  (account_id,client_id,position)
#  index_client_checklist_items_on_account_id       (account_id)
#  index_client_checklist_items_on_client_id        (client_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#
class ClientChecklistItem < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :client

  has_many :competency_checklist_items, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :active_only, -> { where(active: true).order(:position, :id) }

  def match_terms
    value = read_attribute(:match_terms)
    value.is_a?(Array) ? value : []
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: account_permission_grants
#
#  id             :bigint           not null, primary key
#  capability_key :string           not null
#  granted        :boolean          default(FALSE), not null
#  role           :string           default("member"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_account_permission_grants_on_account_id  (account_id)
#  index_account_permission_grants_unique         (account_id,capability_key,role) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountPermissionGrant < ApplicationRecord
  belongs_to :account

  validates :capability_key, presence: true, inclusion: { in: Permissions::Catalog.keys }
  validates :role, presence: true, inclusion: { in: [ Permissions::Catalog::MEMBER_ROLE ] }
  validates :granted, inclusion: { in: [ true, false ] }
  validates :capability_key, uniqueness: { scope: %i[account_id role] }
end

# frozen_string_literal: true

# Deprecated: use Period. Kept for backward compatibility during migration.
# == Schema Information
#
# Table name: competency_checklists
#
#  id                :bigint           not null, primary key
#  closed_at         :datetime
#  opened_at         :datetime         not null
#  period            :date             not null
#  status            :string           default("open"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  client_id         :bigint           not null
#  closed_by_user_id :bigint
#
# Indexes
#
#  idx_on_account_id_client_id_period_7cc7b2bb99     (account_id,client_id,period) UNIQUE
#  index_competency_checklists_on_account_id         (account_id)
#  index_competency_checklists_on_client_id          (client_id)
#  index_competency_checklists_on_closed_by_user_id  (closed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (closed_by_user_id => users.id)
#
class CompetencyChecklist < Period
end

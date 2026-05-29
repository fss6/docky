# == Schema Information
#
# Table name: audit_events
#
#  id           :bigint           not null, primary key
#  event_type   :string           not null
#  metadata     :jsonb            not null
#  subject_type :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  subject_id   :bigint           not null
#  user_id      :bigint
#
# Indexes
#
#  index_audit_events_on_account_event_and_created_at  (account_id,event_type,created_at)
#  index_audit_events_on_account_id                    (account_id)
#  index_audit_events_on_subject                       (subject_type,subject_id)
#  index_audit_events_on_user_id                       (user_id)
#  index_audit_events_on_user_id_and_created_at        (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class AuditEvent < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true

  validates :event_type, presence: true
end

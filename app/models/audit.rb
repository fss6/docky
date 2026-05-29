# frozen_string_literal: true

# == Schema Information
#
# Table name: audits
#
#  id              :bigint           not null, primary key
#  action          :string
#  associated_type :string
#  auditable_type  :string
#  audited_changes :text
#  comment         :string
#  remote_address  :string
#  request_uuid    :string
#  user_type       :string
#  username        :string
#  version         :integer          default(0)
#  created_at      :datetime         not null
#  account_id      :bigint
#  associated_id   :bigint
#  auditable_id    :bigint
#  user_id         :bigint
#
# Indexes
#
#  associated_index                           (associated_type,associated_id)
#  auditable_index                            (auditable_type,auditable_id,version)
#  index_audits_on_account_id                 (account_id)
#  index_audits_on_account_id_and_created_at  (account_id,created_at)
#  index_audits_on_created_at                 (created_at)
#  index_audits_on_request_uuid               (request_uuid)
#  user_index                                 (user_id,user_type)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Audit < Audited::Audit
  belongs_to :account, optional: true

  before_validation :assign_account_id, on: :create
  before_validation :normalize_audited_changes_for_yaml, on: :create

  private

  def assign_account_id
    return if account_id.present?

    self.account_id = auditable_account_id || associated_account_id || ActsAsTenant.current_tenant&.id
  end

  def auditable_account_id
    auditable&.respond_to?(:account_id) ? auditable.account_id : nil
  end

  def associated_account_id
    associated&.respond_to?(:account_id) ? associated.account_id : nil
  end

  # Evita falhas de serialização YAML segura (Psych::DisallowedClass),
  # convertendo tipos não escalares (ex.: Date/Time) em String.
  def normalize_audited_changes_for_yaml
    return if audited_changes.blank?

    self.audited_changes = normalize_yaml_value(audited_changes)
  end

  def normalize_yaml_value(value)
    case value
    when Hash
      value.transform_values { |entry| normalize_yaml_value(entry) }
    when Array
      value.map { |entry| normalize_yaml_value(entry) }
    when Date, Time, DateTime, ActiveSupport::TimeWithZone
      value.iso8601
    else
      value
    end
  end
end

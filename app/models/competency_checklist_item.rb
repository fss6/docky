# == Schema Information
#
# Table name: competency_checklist_items
#
#  id                       :bigint           not null, primary key
#  match_terms              :jsonb            not null
#  name_snapshot            :string           not null
#  received_at              :datetime
#  state                    :string           default("pending"), not null
#  validated_at             :datetime
#  validation_note          :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  client_checklist_item_id :bigint
#  competency_checklist_id  :bigint           not null
#  last_document_id         :bigint
#  validated_by_user_id     :bigint
#
# Indexes
#
#  idx_comp_checklist_items_on_competency_and_template           (competency_checklist_id,client_checklist_item_id) UNIQUE
#  index_competency_checklist_items_on_client_checklist_item_id  (client_checklist_item_id)
#  index_competency_checklist_items_on_competency_checklist_id   (competency_checklist_id)
#  index_competency_checklist_items_on_last_document_id          (last_document_id)
#  index_competency_checklist_items_on_state                     (state)
#  index_competency_checklist_items_on_validated_by_user_id      (validated_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_checklist_item_id => client_checklist_items.id)
#  fk_rails_...  (competency_checklist_id => competency_checklists.id)
#  fk_rails_...  (last_document_id => documents.id)
#  fk_rails_...  (validated_by_user_id => users.id)
#
class CompetencyChecklistItem < ApplicationRecord
  belongs_to :competency_checklist,
             class_name: "Period",
             foreign_key: :competency_checklist_id,
             inverse_of: :items
  belongs_to :client_checklist_item, optional: true
  belongs_to :last_document, class_name: "Document", optional: true
  belongs_to :validated_by_user, class_name: "User", optional: true, inverse_of: :validated_competency_checklist_items

  enum :state, {
    pending: "pending",
    received: "received",
    validated: "validated"
  }, default: :pending

  validates :name_snapshot, presence: true
  validate :last_document_must_match_checklist_competency

  alias period competency_checklist
  alias period= competency_checklist=

  def match_terms
    value = read_attribute(:match_terms)
    value.is_a?(Array) ? value : []
  end

  def mark_validated!(user:)
    update!(
      state: :validated,
      validated_by_user: user,
      validated_at: Time.current
    )
  end

  def mark_pending!
    update!(
      state: :pending,
      validated_by_user: nil,
      validated_at: nil
    )
  end

  def awaiting_receipt?
    pending? && last_document_id.blank?
  end

  def complete_for_collection?
    !awaiting_receipt?
  end

  private

  def last_document_must_match_checklist_competency
    period_record = competency_checklist
    return if last_document.blank? || period_record.blank?

    doc = last_document
    expected_period = period_record.period

    period_match = doc.period_id.present? && doc.period_id == period_record.id
    legacy_match = doc.collection_period == expected_period
    valid = doc.account_id == period_record.account_id &&
      doc.client_id == period_record.client_id &&
      (period_match || legacy_match)

    return if valid

    errors.add(:last_document, "deve pertencer ao cliente e competencia do checklist")
  end
end

# frozen_string_literal: true

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
class ClientMonthlyChecklistItem < CompetencyChecklistItem
  self.table_name = "competency_checklist_items"
end

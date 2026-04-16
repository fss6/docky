# frozen_string_literal: true

class CreateCompetencyChecklists < ActiveRecord::Migration[8.0]
  def change
    create_table :client_checklist_items, if_not_exists: true do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.jsonb :match_terms, default: [], null: false

      t.timestamps
    end

    add_index :client_checklist_items, [:account_id, :client_id, :active], if_not_exists: true
    add_index :client_checklist_items, [:account_id, :client_id, :position], if_not_exists: true

    create_table :competency_checklists, if_not_exists: true do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.date :period, null: false

      t.timestamps
    end

    add_index :competency_checklists, [:account_id, :client_id, :period], unique: true, if_not_exists: true

    create_table :competency_checklist_items, if_not_exists: true do |t|
      t.references :competency_checklist, null: false, foreign_key: true
      t.references :client_checklist_item, null: false, foreign_key: true
      t.references :last_document, foreign_key: { to_table: :documents }
      t.references :validated_by_user, foreign_key: { to_table: :users }
      t.string :name_snapshot, null: false
      t.string :state, default: "pending", null: false
      t.datetime :received_at
      t.datetime :validated_at
      t.text :validation_note

      t.timestamps
    end

    add_index :competency_checklist_items, :client_checklist_item_id, if_not_exists: true
    add_index :competency_checklist_items, [:competency_checklist_id, :client_checklist_item_id],
              unique: true,
              name: "idx_comp_checklist_items_on_competency_and_template",
              if_not_exists: true
    add_index :competency_checklist_items, :competency_checklist_id, if_not_exists: true
    add_index :competency_checklist_items, :last_document_id, if_not_exists: true
    add_index :competency_checklist_items, :state, if_not_exists: true
    add_index :competency_checklist_items, :validated_by_user_id, if_not_exists: true
  end
end

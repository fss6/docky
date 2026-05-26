# frozen_string_literal: true

class ClientOnboardingF07 < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :status, :string, null: false, default: "active"
    add_column :clients, :onboarding_kind, :string

    add_index :clients, :status

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE clients SET status = 'active' WHERE status IS NULL OR status = '';
        SQL
      end
    end

    create_table :onboarding_templates do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.string :kind, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :onboarding_templates, %i[account_id kind], unique: true
    add_index :onboarding_templates, :account_id

    create_table :onboarding_template_items do |t|
      t.bigint :onboarding_template_id, null: false
      t.string :name, null: false
      t.text :help_text
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :onboarding_template_items, %i[onboarding_template_id position],
              name: "index_onboarding_template_items_on_template_and_position"

    create_table :onboarding_checklists do |t|
      t.bigint :account_id, null: false
      t.bigint :client_id, null: false
      t.string :status, null: false, default: "in_progress"
      t.string :onboarding_kind, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :onboarding_checklists, :client_id, unique: true
    add_index :onboarding_checklists, :account_id

    create_table :onboarding_checklist_items do |t|
      t.bigint :onboarding_checklist_id, null: false
      t.string :name, null: false
      t.text :help_text
      t.integer :position, null: false, default: 0
      t.string :state, null: false, default: "pending"
      t.bigint :last_document_id
      t.bigint :validated_by_user_id
      t.datetime :received_at
      t.datetime :validated_at
      t.timestamps
    end
    add_index :onboarding_checklist_items, :onboarding_checklist_id
    add_index :onboarding_checklist_items, :last_document_id

    add_column :upload_invites, :purpose, :string, null: false, default: "monthly"
    change_column_null :upload_invites, :period, true
    add_index :upload_invites, %i[client_id purpose], where: "revoked_at IS NULL",
              name: "index_upload_invites_on_client_purpose_active"

    add_column :settings, :onboarding_share_whatsapp_template, :text
    add_column :settings, :onboarding_share_email_subject_template, :string
    add_column :settings, :onboarding_share_email_body_template, :text

    add_foreign_key :onboarding_templates, :accounts
    add_foreign_key :onboarding_template_items, :onboarding_templates
    add_foreign_key :onboarding_checklists, :accounts
    add_foreign_key :onboarding_checklists, :clients
    add_foreign_key :onboarding_checklist_items, :onboarding_checklists
    add_foreign_key :onboarding_checklist_items, :documents, column: :last_document_id
    add_foreign_key :onboarding_checklist_items, :users, column: :validated_by_user_id
  end
end

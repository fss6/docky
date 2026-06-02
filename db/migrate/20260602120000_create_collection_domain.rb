# frozen_string_literal: true

class CreateCollectionDomain < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.boolean :auto_confirm_receipt, null: false, default: true
      t.time :quiet_hours_start, null: false, default: "2000-01-01 08:00:00"
      t.time :quiet_hours_end, null: false, default: "2000-01-01 19:00:00"
      t.integer :max_messages_per_client_per_day, null: false, default: 1
      t.string :timezone, null: false, default: "America/Sao_Paulo"
      t.timestamps
    end

    create_table :collection_steps do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.integer :offset_days, null: false
      t.string :name, null: false
      t.string :kind, null: false, default: "client_reminder"
      t.boolean :email_enabled, null: false, default: false
      t.boolean :whatsapp_enabled, null: false, default: false
      t.string :email_subject_template
      t.text :email_body_template
      t.text :whatsapp_body_template
      t.string :whatsapp_template_name
      t.timestamps
    end

    add_index :collection_steps, %i[account_id offset_days], unique: true
    add_index :collection_steps, %i[account_id position]

    create_table :client_collection_preferences do |t|
      t.references :client, null: false, foreign_key: true, index: { unique: true }
      t.datetime :email_opted_out_at
      t.datetime :whatsapp_opted_out_at
      t.string :whatsapp_opt_out_source
      t.timestamps
    end

    create_table :collection_dispatches do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :period, null: false, foreign_key: { to_table: :competency_checklists }
      t.references :collection_step, null: false, foreign_key: true
      t.string :channel, null: false
      t.string :status, null: false, default: "scheduled"
      t.string :skip_reason
      t.string :rendered_subject
      t.text :rendered_body
      t.string :provider_message_id
      t.datetime :sent_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :collection_dispatches,
              %i[client_id period_id collection_step_id channel],
              unique: true,
              name: "index_collection_dispatches_unique_per_cycle"
    add_index :collection_dispatches, %i[account_id status created_at]
    add_index :collection_dispatches, :provider_message_id

    create_table :collection_delivery_events do |t|
      t.references :collection_dispatch, null: false, foreign_key: true
      t.string :event, null: false
      t.datetime :occurred_at, null: false
      t.string :reliability_tier, null: false, default: "strong"
      t.jsonb :raw_payload, null: false, default: {}
      t.timestamps
    end

    add_index :collection_delivery_events, %i[collection_dispatch_id event occurred_at],
              name: "index_collection_delivery_events_on_dispatch_event"
  end
end

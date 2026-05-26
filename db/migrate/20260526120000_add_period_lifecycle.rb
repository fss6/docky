# frozen_string_literal: true

class AddPeriodLifecycle < ActiveRecord::Migration[8.0]
  def change
    change_table :competency_checklists, bulk: true do |t|
      t.string :status, null: false, default: "open"
      t.datetime :opened_at
      t.datetime :closed_at
      t.references :closed_by_user, foreign_key: { to_table: :users }
    end

    add_reference :documents, :period, foreign_key: { to_table: :competency_checklists }, index: true
    add_index :documents, %i[client_id period_id created_at],
              name: "index_documents_on_client_period_created"

    reversible do |dir|
      dir.up { backfill_period_lifecycle }
    end
  end

  private

  def backfill_period_lifecycle
    say_with_time "Backfilling competency_checklists lifecycle columns" do
      execute <<~SQL.squish
        UPDATE competency_checklists
        SET status = 'open',
            opened_at = COALESCE(opened_at, created_at)
        WHERE opened_at IS NULL
      SQL
    end

    change_column_null :competency_checklists, :opened_at, false

    say_with_time "Backfilling documents.period_id from collection_period" do
      execute <<~SQL.squish
        UPDATE documents d
        SET period_id = cc.id
        FROM competency_checklists cc
        WHERE d.client_id = cc.client_id
          AND d.collection_period = cc.period
          AND d.period_id IS NULL
      SQL
    end
  end
end

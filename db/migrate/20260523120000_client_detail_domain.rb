# frozen_string_literal: true

class ClientDetailDomain < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :monthly_deadline_day, :integer, default: 10, null: false

    add_reference :documents, :client, foreign_key: true
    add_column :documents, :collection_period, :date
    add_index :documents, %i[client_id collection_period created_at],
              name: "index_documents_on_client_collection_created"

    create_table :upload_invites do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.date :period, null: false
      t.string :token, null: false
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.datetime :expires_at
      t.datetime :revoked_at
      t.integer :access_count, default: 0, null: false
      t.timestamps
    end

    add_index :upload_invites, :token, unique: true
    add_index :upload_invites, %i[client_id period created_at],
              name: "index_upload_invites_on_client_period_created"

    reversible do |dir|
      dir.up { backfill_document_client_period }
    end
  end

  private

  def backfill_document_client_period
    say_with_time "Backfilling documents.client_id and collection_period" do
      execute <<~SQL.squish
        UPDATE documents
        SET client_id = folders.client_id,
            collection_period = CASE
              WHEN folders.name ~ '^[0-9]{4}-[0-9]{2}$'
              THEN to_date(folders.name || '-01', 'YYYY-MM-DD')
              ELSE NULL
            END
        FROM folders
        WHERE documents.folder_id = folders.id
          AND folders.client_id IS NOT NULL
      SQL
    end
  end
end

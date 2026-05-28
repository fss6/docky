# frozen_string_literal: true

class AddArchivedToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :archived_at, :datetime
    add_reference :clients, :archived_by_user, foreign_key: { to_table: :users }, index: true
    add_index :clients, :archived_at
  end
end

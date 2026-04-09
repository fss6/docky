class CreateWikiLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :wiki_logs do |t|
      t.references :account,  null: false, foreign_key: true
      t.string  :operation,   null: false
      t.integer :document_id
      t.integer :wiki_page_id
      t.text    :details
      t.timestamps
    end

    add_index :wiki_logs, [:account_id, :created_at]
  end
end

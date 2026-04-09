class CreateWikiPages < ActiveRecord::Migration[8.0]
  def change
    create_table :wiki_pages do |t|
      t.references :account, null: false, foreign_key: true
      t.string  :slug,               null: false
      t.string  :title,              null: false
      t.text    :content
      t.string  :page_type,          null: false
      t.integer :source_document_id
      t.timestamps
    end

    add_index :wiki_pages, [:account_id, :slug], unique: true
    add_index :wiki_pages, :page_type
  end
end

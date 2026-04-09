class CreateWikiLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :wiki_links do |t|
      t.references :source_page, null: false, foreign_key: { to_table: :wiki_pages }
      t.references :target_page, null: false, foreign_key: { to_table: :wiki_pages }
      t.string :link_type
      t.timestamps
    end

    add_index :wiki_links, [:source_page_id, :target_page_id], unique: true
  end
end

class CreateWikiSchemas < ActiveRecord::Migration[8.0]
  def change
    create_table :wiki_schemas do |t|
      t.references :account, null: false, foreign_key: true
      t.text :instructions
      t.timestamps
    end
  end
end

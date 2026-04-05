class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role
      t.text :content
      t.jsonb :sources
      t.jsonb :metadata, null: false, default: {}
      t.boolean :streaming, null: false, default: false

      t.timestamps
    end
  end
end

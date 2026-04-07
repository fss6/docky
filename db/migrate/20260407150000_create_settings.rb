class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.boolean :generate_tags_automatically, null: false, default: true

      t.timestamps
    end
  end
end

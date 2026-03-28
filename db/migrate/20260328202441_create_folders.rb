class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end

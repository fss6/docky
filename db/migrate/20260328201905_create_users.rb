class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true
      t.string :email
      t.string :name
      t.string :role
      t.boolean :active

      t.timestamps
    end
  end
end

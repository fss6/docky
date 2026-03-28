class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name
      t.references :plan, null: false, foreign_key: true
      t.boolean :active
      t.text :description

      t.timestamps
    end
  end
end

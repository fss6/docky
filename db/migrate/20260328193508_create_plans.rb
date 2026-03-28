class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :price
      t.string :status

      t.timestamps
    end
  end
end

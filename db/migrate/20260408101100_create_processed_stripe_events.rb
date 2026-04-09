class CreateProcessedStripeEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :processed_stripe_events do |t|
      t.string :event_id, null: false

      t.timestamps
    end

    add_index :processed_stripe_events, :event_id, unique: true
  end
end

class AddStripeFieldsToAccountsAndSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :stripe_customer_id, :string
    add_column :accounts, :billing_status, :string, null: false, default: "pending"
    add_index :accounts, :stripe_customer_id, unique: true

    add_column :subscriptions, :stripe_subscription_id, :string
    add_column :subscriptions, :stripe_price_id, :string
    add_column :subscriptions, :stripe_checkout_session_id, :string
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :stripe_checkout_session_id, unique: true
  end
end

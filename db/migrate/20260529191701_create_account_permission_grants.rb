# frozen_string_literal: true

class CreateAccountPermissionGrants < ActiveRecord::Migration[8.0]
  def up
    create_table :account_permission_grants do |t|
      t.references :account, null: false, foreign_key: true
      t.string :capability_key, null: false
      t.string :role, null: false, default: "member"
      t.boolean :granted, null: false, default: false

      t.timestamps
    end

    add_index :account_permission_grants,
              %i[account_id capability_key role],
              unique: true,
              name: "index_account_permission_grants_unique"

    seed_existing_accounts
  end

  def down
    drop_table :account_permission_grants
  end

  private

  def seed_existing_accounts
    say_with_time "Seeding default permission grants for existing accounts" do
      Account.find_each do |account|
        Permissions::SeedDefaults.call(account: account)
      end
    end
  end
end

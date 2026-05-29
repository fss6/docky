# frozen_string_literal: true

class AddFoundingUserToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :founding_user, :boolean, null: false, default: false

    backfill_founding_users

    add_index :users,
              %i[account_id founding_user],
              unique: true,
              where: "founding_user = true",
              name: "index_users_on_account_id_founding_user"
  end

  def down
    remove_index :users, name: "index_users_on_account_id_founding_user"
    remove_column :users, :founding_user
  end

  private

  def backfill_founding_users
    say_with_time "Backfilling founding_user per account" do
      Account.find_each do |account|
        founding = account.users.order(:created_at, :id).first
        next unless founding

        founding.update_columns(
          founding_user: true,
          role: User.roles[:owner],
          active: true,
          updated_at: Time.current
        )
      end
    end
  end
end

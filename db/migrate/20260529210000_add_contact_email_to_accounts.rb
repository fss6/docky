# frozen_string_literal: true

class AddContactEmailToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :contact_email, :string
  end
end

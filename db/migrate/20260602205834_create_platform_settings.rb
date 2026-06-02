# frozen_string_literal: true

class CreatePlatformSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :platform_settings, id: false do |t|
      t.string :singleton_key, null: false, primary_key: true, default: "default"

      t.string :mail_delivery
      t.string :smtp_address
      t.integer :smtp_port
      t.string :smtp_domain
      t.string :smtp_username
      t.string :smtp_authentication, default: "plain"
      t.string :mailer_from
      t.text :smtp_password

      t.string :whatsapp_phone_number_id
      t.string :whatsapp_waba_id
      t.string :whatsapp_api_version, default: "v21.0"
      t.string :whatsapp_verify_token
      t.text :whatsapp_access_token
      t.text :whatsapp_app_secret

      t.timestamps
    end
  end
end

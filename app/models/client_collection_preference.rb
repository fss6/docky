# frozen_string_literal: true

# == Schema Information
#
# Table name: client_collection_preferences
#
#  id                      :bigint           not null, primary key
#  email_opted_out_at      :datetime
#  whatsapp_opt_out_source :string
#  whatsapp_opted_out_at   :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  client_id               :bigint           not null
#
# Indexes
#
#  index_client_collection_preferences_on_client_id  (client_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#
class ClientCollectionPreference < ApplicationRecord
  belongs_to :client

  enum :whatsapp_opt_out_source, {
    reply_parar: "reply_parar",
    link: "link",
    manual: "manual"
  }, prefix: true, validate: { allow_nil: true }

  def email_opted_out?
    email_opted_out_at.present?
  end

  def whatsapp_opted_out?
    whatsapp_opted_out_at.present?
  end

  def self.ensure_for!(client)
    client.collection_preference || client.create_collection_preference!
  end
end

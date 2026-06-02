# frozen_string_literal: true

module Collection
  class UnsubscribeToken
    def self.generate(client)
      verifier.generate(client.id)
    end

    def self.verify(token)
      client_id = verifier.verify(token)
      Client.find(client_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def self.verifier
      Rails.application.message_verifier("collection_email_unsubscribe")
    end
  end
end

# frozen_string_literal: true

require "openssl"

module Whatsapp
  class WebhookSignature
    def self.valid?(payload:, signature_header:)
      new(payload: payload, signature_header: signature_header).valid?
    end

    def initialize(payload:, signature_header:)
      @payload = payload
      @signature_header = signature_header.to_s
    end

    def valid?
      secret = PlatformConfig.app_secret
      return false if secret.blank? || @signature_header.blank?

      expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, @payload)}"
      ActiveSupport::SecurityUtils.secure_compare(expected, @signature_header)
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Whatsapp
  class WebhookSignatureTest < ActiveSupport::TestCase
    test "valid signature" do
      secret = "test_secret"
      payload = '{"object":"whatsapp_business_account"}'
      signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, payload)}"

      PlatformConfig.stub(:app_secret, secret) do
        assert WebhookSignature.valid?(payload: payload, signature_header: signature)
      end
    end

    test "invalid signature" do
      PlatformConfig.stub(:app_secret, "secret") do
        assert_not WebhookSignature.valid?(payload: "{}", signature_header: "sha256=bad")
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Whatsapp
  class WebhooksControllerTest < ActionDispatch::IntegrationTest
    test "verify challenge" do
      PlatformConfig.stub(:verify_token, "my_verify") do
        get "/webhooks/whatsapp", params: {
          "hub.mode" => "subscribe",
          "hub.verify_token" => "my_verify",
          "hub.challenge" => "challenge123"
        }
        assert_response :success
        assert_equal "challenge123", response.body
      end
    end

    test "reject invalid verify token" do
      PlatformConfig.stub(:verify_token, "expected") do
        get "/webhooks/whatsapp", params: {
          "hub.mode" => "subscribe",
          "hub.verify_token" => "wrong",
          "hub.challenge" => "x"
        }
        assert_response :forbidden
      end
    end
  end
end

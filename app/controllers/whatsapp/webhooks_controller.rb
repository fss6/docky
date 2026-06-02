# frozen_string_literal: true

module Whatsapp
  class WebhooksController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :find_current_tenant
    skip_before_action :set_nav_client_autocomplete_json
    skip_after_action :verify_authorized

    def verify
      mode = params["hub.mode"]
      token = params["hub.verify_token"]
      challenge = params["hub.challenge"]

      if mode == "subscribe" && token == PlatformConfig.verify_token
        render plain: challenge, status: :ok
      else
        head :forbidden
      end
    end

    def receive
      payload = request.raw_post
      unless WebhookSignature.valid?(payload: payload, signature_header: request.headers["X-Hub-Signature-256"])
        head :unauthorized
        return
      end

      ProcessWebhook.call(JSON.parse(payload))
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end
  end
end

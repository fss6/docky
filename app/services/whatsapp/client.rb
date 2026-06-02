# frozen_string_literal: true

require "net/http"
require "json"

module Whatsapp
  class Client
    class Error < StandardError
      attr_reader :response_body, :status_code

      def initialize(message, response_body: nil, status_code: nil)
        super(message)
        @response_body = response_body
        @status_code = status_code
      end
    end

    def send_template_message(to:, template_name:, language_code: "pt_BR", components: [])
      payload = {
        messaging_product: "whatsapp",
        to: PhoneNormalizer.normalize(to),
        type: "template",
        template: {
          name: template_name,
          language: { code: language_code },
          components: components
        }
      }
      post_messages(payload)
    end

    def send_text_message(to:, body:)
      payload = {
        messaging_product: "whatsapp",
        to: PhoneNormalizer.normalize(to),
        type: "text",
        text: { body: body }
      }
      post_messages(payload)
    end

    private

    def post_messages(payload)
      raise Error, "WhatsApp platform not configured" unless PlatformConfig.configured?

      uri = URI("#{PlatformConfig.graph_base_url}/#{PlatformConfig.phone_number_id}/messages")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{PlatformConfig.access_token}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body) rescue {}
      unless response.is_a?(Net::HTTPSuccess)
        raise Error.new(
          body.dig("error", "message") || "WhatsApp API error",
          response_body: body,
          status_code: response.code.to_i
        )
      end

      body
    end
  end
end

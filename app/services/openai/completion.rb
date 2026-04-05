# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Openai
  # Non-streaming chat completions (POST /v1/chat/completions).
  class Completion
    class Error < StandardError; end
    class MissingApiKeyError < Error; end

    DEFAULT_MODEL = "gpt-4o-mini"
    API_URL = "https://api.openai.com/v1/chat/completions"

    def self.call(messages:, model: nil, max_tokens: 64, temperature: 0.3)
      new(messages: messages, model: model, max_tokens: max_tokens, temperature: temperature).call
    end

    def initialize(messages:, model: nil, max_tokens: 64, temperature: 0.3)
      @messages = messages
      @model = model || ENV.fetch("OPENAI_TITLE_MODEL", ENV.fetch("OPENAI_CHAT_MODEL", DEFAULT_MODEL))
      @max_tokens = max_tokens
      @temperature = temperature
    end

    def call
      raise MissingApiKeyError, "OPENAI_API_KEY não configurada" if ENV["OPENAI_API_KEY"].to_s.blank?
      raise Error, "messages vazio" if @messages.blank?

      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(
        model: @model,
        messages: @messages,
        max_tokens: @max_tokens,
        temperature: @temperature
      )

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        err_body = response.body.to_s.truncate(800)
        raise Error, "OpenAI completion (#{response.code}): #{err_body}"
      end

      json = JSON.parse(response.body)
      content = json.dig("choices", 0, "message", "content")
      raise Error, "Resposta vazia da OpenAI" if content.blank?

      content.to_s
    rescue JSON::ParserError => e
      raise Error, "JSON inválido: #{e.message}"
    end
  end
end

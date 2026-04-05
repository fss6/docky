# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Openai
  # Streaming chat completions (POST /v1/chat/completions, stream: true).
  class Chat
    class Error < StandardError; end
    class MissingApiKeyError < Error; end

    DEFAULT_MODEL = "gpt-4o-mini"
    API_URL = "https://api.openai.com/v1/chat/completions"

    def self.stream(messages:, model: nil, &block)
      new(messages: messages, model: model).stream(&block)
    end

    def initialize(messages:, model: nil)
      @messages = messages
      @model = model || ENV.fetch("OPENAI_CHAT_MODEL", DEFAULT_MODEL)
    end

    def stream(&block)
      raise MissingApiKeyError, "OPENAI_API_KEY não configurada" if ENV["OPENAI_API_KEY"].to_s.blank?
      raise Error, "messages vazio" if @messages.blank?

      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 300

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(
        model: @model,
        messages: @messages,
        stream: true
      )

      buffer = +""
      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          err_body = response.body.to_s.truncate(800)
          raise Error, "OpenAI chat (#{response.code}): #{err_body}"
        end

        response.read_body do |chunk|
          buffer << chunk
          while buffer.include?("\n")
            line, buffer = buffer.split("\n", 2)
            process_sse_line(line, &block)
          end
        end
        process_sse_line(buffer, &block) if buffer.present?
      end
    end

    private

    def process_sse_line(line, &block)
      line = line.to_s.strip
      return if line.empty?
      return if line == "data: [DONE]"
      return unless line.start_with?("data: ")

      payload = line.delete_prefix("data: ").strip
      json = JSON.parse(payload)
      token = json.dig("choices", 0, "delta", "content")
      block.call(token) if token.present?
    rescue JSON::ParserError
      # ignora linhas SSE malformadas
    end
  end
end

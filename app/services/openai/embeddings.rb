# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Openai
  # Cliente mínimo para POST /v1/embeddings (batch de textos → vetores).
  class Embeddings
    class Error < StandardError; end
    class MissingApiKeyError < Error; end

    DEFAULT_MODEL = "text-embedding-3-small"
    API_URL = "https://api.openai.com/v1/embeddings"

    # @param texts [Array<String>] não vazios
    # @return [Array<Array<Float>>] um vetor por texto, mesma ordem
    def self.call(texts:, model: nil)
      new(texts: texts, model: model).call
    end

    def initialize(texts:, model: nil)
      @texts = Array(texts).map(&:to_s)
      @model = model || ENV.fetch("OPENAI_EMBEDDING_MODEL", DEFAULT_MODEL)
    end

    def call
      raise MissingApiKeyError, "OPENAI_API_KEY não configurada" if ENV["OPENAI_API_KEY"].to_s.blank?
      raise Error, "texts vazio" if @texts.empty?

      payload = {
        model: @model,
        input: @texts
      }

      response = http_post(API_URL, payload)
      parsed = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        message = parsed.dig("error", "message") || parsed["message"] || response.body.to_s.truncate(500)
        raise Error, "OpenAI embeddings (#{response.code}): #{message}"
      end

      data = parsed["data"] || []
      ordered = data.sort_by { |d| d["index"].to_i }
      vectors = ordered.map { |d| d["embedding"] }
      if vectors.size != @texts.size
        raise Error, "OpenAI retornou #{vectors.size} vetores para #{@texts.size} textos"
      end

      vectors
    rescue JSON::ParserError => e
      raise Error, "Resposta inválida da OpenAI: #{e.message}"
    end

    private

    def http_post(uri_string, body_hash)
      uri = URI(uri_string)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body_hash)

      http.request(request)
    end
  end
end

# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module MistralOcr
  # Chama a API Document AI / OCR da Mistral. Documentação:
  # https://docs.mistral.ai/capabilities/document_ai/basic_ocr
  class ExtractContent
    class Error < StandardError; end

    DEFAULT_ENDPOINT = "https://api.mistral.ai/v1/ocr"
    DEFAULT_MODEL = "mistral-ocr-latest"

    def self.call(document:)
      new(document).call
    end

    def initialize(document)
      @document = document
    end

    def call
      api_key = ENV["MISTRAL_OCR_API_KEY"]
      raise Error, "MISTRAL_OCR_API_KEY não configurada" if api_key.blank?

      attachment = @document.file
      raise Error, "Arquivo não anexado" unless attachment.attached?

      url = attachment_url_for_mistral(attachment)
      payload = {
        model: ENV.fetch("MISTRAL_OCR_MODEL", DEFAULT_MODEL),
        document: mistral_document_payload(attachment, url)
      }

      response = http_post(ocr_endpoint, api_key, payload)
      parsed = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        message =
          if parsed.is_a?(Hash)
            parsed["message"] || parsed["detail"] || response.body.to_s.truncate(500)
          else
            response.body.to_s.truncate(500)
          end
        raise Error, "Mistral OCR (#{response.code}): #{message}"
      end

      pages = parsed["pages"] || []
      text = pages.filter_map { |p| p["markdown"].presence }.join("\n\n")

      { text: text, response: parsed }
    rescue JSON::ParserError
      code = (defined?(response) && response) ? response.code : "?"
      raise Error, "Mistral OCR (#{code}): resposta inválida (não é JSON)"
    end

    private

    def ocr_endpoint
      ENV.fetch("MISTRAL_OCR_URL", DEFAULT_ENDPOINT)
    end

    # Mistral precisa de uma URL publicamente acessível. Com S3 (ou compatível),
    # a URL assinada funciona. Em disco, é preciso host/protocol acessíveis por fora.
    def attachment_url_for_mistral(attachment, expires_in: 15.minutes)
      blob = attachment.blob
      was_set = false
      # Não usar ActiveStorage::Service::DiskService em is_a? — em apps só com S3 a
      # constante pode não estar carregada e quebra o autoload.
      if blob.service.class.name == "ActiveStorage::Service::DiskService"
        ActiveStorage::Current.url_options = active_storage_url_options
        was_set = true
      end
      attachment.url(expires_in: expires_in)
    ensure
      ActiveStorage::Current.url_options = nil if was_set
    end

    def active_storage_url_options
      host = ENV.fetch(
        "ACTIVE_STORAGE_EXTERNAL_HOST",
        Rails.application.routes.default_url_options[:host].presence || "localhost:3000"
      )
      protocol = ENV.fetch("ACTIVE_STORAGE_EXTERNAL_PROTOCOL", "http")
      { host: host, protocol: protocol }
    end

    def mistral_document_payload(attachment, url)
      filename = attachment.filename.to_s
      if attachment.content_type.to_s.start_with?("image/")
        { type: "image_url", image_url: url }
      else
        {
          type: "document_url",
          document_url: url,
          document_name: filename.presence
        }.compact
      end
    end

    def http_post(uri_string, api_key, body_hash)
      uri = URI(uri_string)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 30
      http.read_timeout = 180

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body_hash)

      http.request(request)
    end
  end
end

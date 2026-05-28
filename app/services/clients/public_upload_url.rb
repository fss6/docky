# frozen_string_literal: true

module Clients
  class PublicUploadUrl
    include Rails.application.routes.url_helpers

    def self.for(token:)
      new(token).call
    end

    def initialize(token)
      @token = token
    end

    def call
      public_folder_upload_url(token: @token, host: host, protocol: protocol)
    end

    private

    def host
      raw = ENV["PUBLIC_APP_HOST"].presence || ENV.fetch("MAILER_DEFAULT_HOST", "localhost")
      raw.sub(/\Aportal\./, "")
    end

    def protocol
      return "http" if Rails.env.development?

      "https"
    end
  end
end

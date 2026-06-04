# frozen_string_literal: true

module PlatformSettings
  class WhatsappConfig
    REQUIRED_KEYS = %i[access_token phone_number_id app_secret verify_token].freeze

    class << self
      def configured?
        missing_keys.empty?
      end

      def missing_keys
        REQUIRED_KEYS.select { |key| public_send(key).blank? }
      end

      def access_token
        record&.whatsapp_access_token.presence || env_fetch(:access_token)
      end

      def phone_number_id
        record&.whatsapp_phone_number_id.presence || env_fetch(:phone_number_id)
      end

      def waba_id
        record&.whatsapp_waba_id.presence || env_fetch(:waba_id)
      end

      def app_secret
        record&.whatsapp_app_secret.presence || env_fetch(:app_secret)
      end

      def verify_token
        record&.whatsapp_verify_token.presence || env_fetch(:verify_token)
      end

      def api_version
        record&.whatsapp_api_version.presence || env_fetch(:api_version).presence || "v21.0"
      end

      def graph_base_url
        "https://graph.facebook.com/#{api_version}"
      end

      def from_database?
        record&.whatsapp_configured_in_db? || false
      end

      private

      def record
        return unless PlatformSetting.table_ready?

        PlatformSetting.current
      end

      def env_fetch(key)
        env_key = "WHATSAPP_#{key.to_s.upcase}"
        ENV[env_key].presence || credentials_hash[key.to_s] || credentials_hash[key]
      end

      def credentials_hash
        @credentials_hash ||= Rails.application.credentials.fetch(:whatsapp, {}).to_h.stringify_keys
      rescue KeyError
        {}
      end
    end
  end
end

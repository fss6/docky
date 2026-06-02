# frozen_string_literal: true

module Whatsapp
  class PlatformConfig
    REQUIRED_KEYS = PlatformSettings::WhatsappConfig::REQUIRED_KEYS

    class << self
      delegate :configured?, :missing_keys, :access_token, :phone_number_id, :waba_id,
               :app_secret, :verify_token, :api_version, :graph_base_url,
               to: PlatformSettings::WhatsappConfig
    end
  end
end

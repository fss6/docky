# frozen_string_literal: true

module PlatformSettings
  class Delivery
    def self.apply!
      return if Rails.env.test?

      SmtpConfig.apply_runtime!
    end
  end
end

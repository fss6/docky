# frozen_string_literal: true

module PlatformSettings
  class SmtpConfig
    class << self
      def configured?
        from_database? || from_env?
      end

      def mode
        return record.mail_delivery if from_database?

        ActionMailerDelivery.env_mode
      end

      def apply_to!(config = Rails.application.config)
        return apply_from_record!(config) if from_database?

        ActionMailerDelivery.apply_from_env!(config)
      end

      def apply_runtime!(mailer = ActionMailer::Base)
        return false unless configured?

        mailer.delivery_method = :smtp
        mailer.perform_deliveries = true
        mailer.raise_delivery_errors = true
        mailer.smtp_settings = smtp_settings
        from = mailer_from
        mailer.default_options = { from: from } if from.present?
        true
      end

      def smtp_settings
        if from_database?
          record_smtp_settings
        else
          ActionMailerDelivery.env_smtp_settings
        end
      end

      def mailer_from
        if from_database?
          record.mailer_from.presence || record.smtp_username
        else
          ActionMailerDelivery.env_mailer_from
        end
      end

      def from_database?
        record.smtp_configured_in_db?
      end

      def from_env?
        ActionMailerDelivery.env_configured?
      end

      private

      def record
        PlatformSetting.current
      end

      def record_smtp_settings
        address, domain = smtp_address_and_domain
        {
          address: address,
          port: record.smtp_port.presence || 587,
          domain: domain,
          user_name: record.smtp_username,
          password: record.smtp_password,
          authentication: (record.smtp_authentication.presence || "plain").to_sym,
          enable_starttls_auto: true
        }
      end

      def smtp_address_and_domain
        case record.mail_delivery
        when "gmail"
          ["smtp.gmail.com", record.smtp_domain.presence || "gmail.com"]
        else
          [
            record.smtp_address.presence || raise(ActionMailerDelivery::ConfigurationError, "smtp_address required"),
            record.smtp_domain.presence || record.smtp_address
          ]
        end
      end

      def apply_from_record!(config)
        apply_runtime!(config.action_mailer)
      end
    end
  end
end

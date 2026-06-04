# frozen_string_literal: true

module PlatformSettings
  class SmtpConfig
    class << self
      def configured?
        from_database? || from_env?
      end

      def mode
        rec = record
        return rec.mail_delivery if rec&.smtp_configured_in_db?

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
        rec = record
        if rec&.smtp_configured_in_db?
          record_smtp_settings(rec)
        else
          ActionMailerDelivery.env_smtp_settings
        end
      end

      def mailer_from
        rec = record
        if rec&.smtp_configured_in_db?
          rec.mailer_from.presence || rec.smtp_username
        else
          ActionMailerDelivery.env_mailer_from
        end
      end

      def from_database?
        record&.smtp_configured_in_db? || false
      end

      def from_env?
        ActionMailerDelivery.env_configured?
      end

      private

      def record
        return unless PlatformSetting.table_ready?

        PlatformSetting.current
      end

      def record_smtp_settings(rec)
        address, domain = smtp_address_and_domain(rec)
        {
          address: address,
          port: rec.smtp_port.presence || 587,
          domain: domain,
          user_name: rec.smtp_username,
          password: rec.smtp_password,
          authentication: (rec.smtp_authentication.presence || "plain").to_sym,
          enable_starttls_auto: true
        }
      end

      def smtp_address_and_domain(rec)
        case rec.mail_delivery
        when "gmail"
          ["smtp.gmail.com", rec.smtp_domain.presence || "gmail.com"]
        else
          [
            rec.smtp_address.presence || raise(ActionMailerDelivery::ConfigurationError, "smtp_address required"),
            rec.smtp_domain.presence || rec.smtp_address
          ]
        end
      end

      def apply_from_record!(config)
        apply_runtime!(config.action_mailer)
      end
    end
  end
end

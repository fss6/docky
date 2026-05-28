# frozen_string_literal: true

module ActionMailerDelivery
  class ConfigurationError < StandardError; end

  def self.mode
    ENV.fetch("MAIL_DELIVERY", "").downcase.strip
  end

  def self.enabled?
    mode.present?
  end

  def self.apply!(config)
    return if Rails.env.test?

    case mode
    when "gmail"
      apply_gmail!(config)
    when "smtp"
      apply_smtp!(config)
    when ""
      # Rails default: no explicit SMTP configuration
    else
      raise ConfigurationError,
            "MAIL_DELIVERY=#{mode.inspect} is invalid. Use gmail, smtp, or leave unset."
    end
  end

  def self.apply_gmail!(config)
    validate_credentials!
    apply_smtp_settings!(
      config,
      address: "smtp.gmail.com",
      domain: ENV.fetch("SMTP_DOMAIN", "gmail.com")
    )
  end

  def self.apply_smtp!(config)
    validate_credentials!
    address = fetch_env!("SMTP_ADDRESS")
    apply_smtp_settings!(
      config,
      address: address,
      domain: ENV.fetch("SMTP_DOMAIN", address)
    )
  end

  def self.apply_smtp_settings!(config, address:, domain:)
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.smtp_settings = {
      address: address,
      port: ENV.fetch("SMTP_PORT", "587").to_i,
      domain: domain,
      user_name: fetch_env!("SMTP_USERNAME"),
      password: fetch_env!("SMTP_PASSWORD"),
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: true
    }

    from = ENV.fetch("MAILER_FROM", ENV["SMTP_USERNAME"])
    config.action_mailer.default_options = { from: from } if from.present?
  end

  def self.validate_credentials!
    fetch_env!("SMTP_USERNAME")
    fetch_env!("SMTP_PASSWORD")
  end

  def self.fetch_env!(key)
    value = ENV[key].to_s.strip
    return value if value.present?

    raise ConfigurationError, "#{key} is required when MAIL_DELIVERY=#{mode.inspect}"
  end
  private_class_method :fetch_env!
end

ActionMailerDelivery.apply!(Rails.application.config)

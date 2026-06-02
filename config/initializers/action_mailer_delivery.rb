# frozen_string_literal: true

module ActionMailerDelivery
  class ConfigurationError < StandardError; end

  def self.enabled?
    PlatformSettings::SmtpConfig.configured?
  end

  def self.env_mode
    ENV.fetch("MAIL_DELIVERY", "").downcase.strip
  end

  def self.env_configured?
    env_mode.present?
  end

  def self.apply!(config)
    return if Rails.env.test?

    PlatformSettings::SmtpConfig.apply_to!(config)
  end

  def self.apply_runtime!(mailer = ActionMailer::Base)
    return false unless enabled?

    PlatformSettings::SmtpConfig.apply_runtime!(mailer)
  end

  def self.apply_from_env!(config)
    return if env_mode.blank?

    case env_mode
    when "gmail"
      apply_gmail_env!(config)
    when "smtp"
      apply_smtp_env!(config)
    else
      raise ConfigurationError,
            "MAIL_DELIVERY=#{env_mode.inspect} is invalid. Use gmail, smtp, or leave unset."
    end
  end

  def self.env_smtp_settings
    address, domain = env_smtp_address_and_domain
    {
      address: address,
      port: ENV.fetch("SMTP_PORT", "587").to_i,
      domain: domain,
      user_name: fetch_env!("SMTP_USERNAME"),
      password: fetch_env!("SMTP_PASSWORD"),
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: true
    }
  end

  def self.env_mailer_from
    ENV.fetch("MAILER_FROM", ENV["SMTP_USERNAME"]).presence
  end

  def self.apply_gmail_env!(config)
    validate_env_credentials!
    apply_env_smtp_settings!(
      config,
      address: "smtp.gmail.com",
      domain: ENV.fetch("SMTP_DOMAIN", "gmail.com")
    )
  end

  def self.apply_smtp_env!(config)
    validate_env_credentials!
    address = fetch_env!("SMTP_ADDRESS")
    apply_env_smtp_settings!(
      config,
      address: address,
      domain: ENV.fetch("SMTP_DOMAIN", address)
    )
  end

  def self.apply_env_smtp_settings!(config, address:, domain:)
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

    from = env_mailer_from
    config.action_mailer.default_options = { from: from } if from.present?
  end

  def self.env_smtp_address_and_domain
    case env_mode
    when "gmail"
      ["smtp.gmail.com", ENV.fetch("SMTP_DOMAIN", "gmail.com")]
    when "smtp"
      address = fetch_env!("SMTP_ADDRESS")
      [address, ENV.fetch("SMTP_DOMAIN", address)]
    else
      raise ConfigurationError, "MAIL_DELIVERY is not set"
    end
  end

  def self.validate_env_credentials!
    fetch_env!("SMTP_USERNAME")
    fetch_env!("SMTP_PASSWORD")
  end

  def self.fetch_env!(key)
    value = ENV[key].to_s.strip
    return value if value.present?

    raise ConfigurationError, "#{key} is required when MAIL_DELIVERY=#{env_mode.inspect}"
  end
  private_class_method :fetch_env!
end

Rails.application.config.to_prepare do
  ActionMailerDelivery.apply!(Rails.application.config) unless Rails.env.test?
end

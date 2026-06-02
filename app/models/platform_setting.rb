# frozen_string_literal: true

# == Schema Information
#
# Table name: platform_settings
#
#  mail_delivery            :string
#  mailer_from              :string
#  singleton_key            :string           default("default"), not null, primary key
#  smtp_address             :string
#  smtp_authentication      :string           default("plain")
#  smtp_domain              :string
#  smtp_password            :text
#  smtp_port                :integer
#  smtp_username            :string
#  whatsapp_access_token    :text
#  whatsapp_api_version     :string           default("v21.0")
#  whatsapp_app_secret      :text
#  whatsapp_verify_token    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  whatsapp_phone_number_id :string
#  whatsapp_waba_id         :string
#
class PlatformSetting < ApplicationRecord
  self.primary_key = "singleton_key"

  CACHE_KEY = "platform_setting/default"
  CACHE_TTL = 1.minute
  MAIL_DELIVERY_MODES = %w[gmail smtp].freeze

  encrypts :smtp_password
  encrypts :whatsapp_access_token
  encrypts :whatsapp_app_secret

  validates :singleton_key, inclusion: { in: %w[default] }
  validates :mail_delivery, inclusion: { in: MAIL_DELIVERY_MODES }, allow_blank: true
  validates :smtp_port, numericality: { only_integer: true, greater_than: 0, less_than: 65_536 }, allow_nil: true
  validate :smtp_complete_when_delivery_set, if: -> { mail_delivery.present? }

  before_validation :normalize_smtp_port
  before_validation :ensure_whatsapp_verify_token
  after_commit :invalidate_cache!

  attr_accessor :smtp_password_confirmation, :skip_smtp_password_validation

  def self.current
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      find_or_create_by!(singleton_key: "default")
    end
  end

  def self.reset_cache!
    Rails.cache.delete(CACHE_KEY)
  end

  def smtp_configured_in_db?
    mail_delivery.present? && smtp_username.present? && smtp_password.present?
  end

  def whatsapp_configured_in_db?
    whatsapp_access_token.present? &&
      whatsapp_phone_number_id.present? &&
      whatsapp_app_secret.present? &&
      whatsapp_verify_token.present?
  end

  private

  def normalize_smtp_port
    self.smtp_port = nil if smtp_port.blank?
  end

  def ensure_whatsapp_verify_token
    self.whatsapp_verify_token = SecureRandom.hex(16) if whatsapp_verify_token.blank?
  end

  def smtp_complete_when_delivery_set
    errors.add(:smtp_username, :blank) if smtp_username.blank?
    return if skip_smtp_password_validation

    errors.add(:smtp_password, :blank) if smtp_password.blank?
  end

  def invalidate_cache!
    self.class.reset_cache!
  end
end

# frozen_string_literal: true

# PlatformSetting stores secrets with +encrypts+; configure keys at boot.
# Do not read +primary_key+ before configure — Rails may raise if credentials are empty.
module ActiveRecordEncryptionSetup
  module_function

  def apply!(app = Rails.application)
    return if Rails.env.test?

    creds = app.credentials.active_record_encryption rescue nil
    if creds.is_a?(Hash) && creds[:primary_key].present?
      ActiveRecord::Encryption.configure(
        primary_key: creds[:primary_key],
        deterministic_key: creds[:deterministic_key],
        key_derivation_salt: creds[:key_derivation_salt]
      )
      return
    end

    secret = app.secret_key_base.to_s
    return if secret.blank?

    digest = ->(label) { Digest::SHA256.hexdigest("#{label}:#{secret}")[0, 32] }

    ActiveRecord::Encryption.configure(
      primary_key: digest.call("primary"),
      deterministic_key: digest.call("deterministic"),
      key_derivation_salt: digest.call("salt")
    )
  end
end

ActiveRecordEncryptionSetup.apply!

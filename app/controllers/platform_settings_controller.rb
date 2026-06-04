# frozen_string_literal: true

class PlatformSettingsController < ApplicationController
  before_action :set_platform_setting
  before_action :authorize_platform_setting, except: %i[regenerate_whatsapp_verify_token send_test_email]

  def show
    @smtp_configured = PlatformSettings::SmtpConfig.configured?
    @whatsapp_configured = Whatsapp::PlatformConfig.configured?
    @whatsapp_missing_keys = Whatsapp::PlatformConfig.missing_keys
    @webhook_url = webhooks_whatsapp_url(host: request.base_url)
  end

  def update
    if @platform_setting.update(platform_setting_params)
      PlatformSettings::Delivery.apply!
      redirect_to platform_settings_path, notice: "Configurações da plataforma atualizadas."
    else
      show_assignments
      render :show, status: :unprocessable_entity
    end
  end

  def regenerate_whatsapp_verify_token
    authorize @platform_setting, :update?
    @platform_setting.update!(whatsapp_verify_token: SecureRandom.hex(16))
    PlatformSettings::Delivery.apply!
    redirect_to platform_settings_path, notice: "Token de verificação do webhook regenerado."
  end

  def send_test_email
    authorize @platform_setting, :update?

    recipient = params[:recipient].presence || current_user.email
    unless recipient.match?(URI::MailTo::EMAIL_REGEXP)
      redirect_to platform_settings_path, alert: "Informe um e-mail de destino válido."
      return
    end

    result = PlatformSettings::SendTestEmail.call(recipient: recipient)
    if result.success
      redirect_to platform_settings_path, notice: "E-mail de teste enviado para #{recipient}."
    else
      redirect_to platform_settings_path, alert: result.error
    end
  end

  private

  def set_platform_setting
    @platform_setting = PlatformSetting.current
  end

  def authorize_platform_setting
    authorize @platform_setting
  end

  def show_assignments
    @smtp_configured = PlatformSettings::SmtpConfig.configured?
    @whatsapp_configured = Whatsapp::PlatformConfig.configured?
    @whatsapp_missing_keys = Whatsapp::PlatformConfig.missing_keys
    @webhook_url = webhooks_whatsapp_url(host: request.base_url)
  end

  def platform_setting_params
    permitted = params.expect(platform_setting: [
      :mail_delivery,
      :smtp_address,
      :smtp_port,
      :smtp_domain,
      :smtp_username,
      :smtp_authentication,
      :mailer_from,
      :smtp_password,
      :whatsapp_phone_number_id,
      :whatsapp_waba_id,
      :whatsapp_api_version,
      :whatsapp_verify_token,
      :whatsapp_access_token,
      :whatsapp_app_secret
    ])

    preserve_secret_if_blank!(permitted, :smtp_password)
    preserve_secret_if_blank!(permitted, :whatsapp_access_token)
    preserve_secret_if_blank!(permitted, :whatsapp_app_secret)

    if permitted[:mail_delivery].blank?
      permitted[:smtp_password] = nil if permitted.key?(:smtp_password)
      @platform_setting.skip_smtp_password_validation = true
    elsif @platform_setting.persisted? && permitted[:smtp_password].blank?
      @platform_setting.skip_smtp_password_validation = true
    end

    permitted
  end

  def preserve_secret_if_blank!(permitted, key)
    permitted.delete(key) if permitted[key].blank?
  end
end

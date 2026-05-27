# frozen_string_literal: true

module Settings
  class OnboardingSharesController < ApplicationController
    before_action :set_setting
    before_action :authorize_policy

    def edit
    end

    def update
      if @setting.update(setting_params)
        redirect_to edit_settings_onboarding_share_path, notice: "Configurações de compartilhamento de onboarding atualizadas com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_setting
      @setting = current_user.account.setting || current_user.account.create_setting!
    end

    def authorize_policy
      authorize @setting
    end

    def setting_params
      params.expect(setting: [
        :onboarding_share_whatsapp_template,
        :onboarding_share_email_subject_template,
        :onboarding_share_email_body_template
      ])
    end
  end
end

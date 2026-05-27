# frozen_string_literal: true

module Settings
  class AiSettingsController < ApplicationController
    before_action :set_setting
    before_action :authorize_policy

    def edit
    end

    def update
      if @setting.update(setting_params)
        redirect_to edit_settings_ai_settings_path, notice: "Configurações de IA atualizadas com sucesso."
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
      params.expect(setting: [:generate_tags_automatically])
    end
  end
end

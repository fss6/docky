class SettingsController < ApplicationController
  before_action :set_setting
  before_action :authorize_policy

  def show
  end

  def update
    if @setting.update(setting_params)
      redirect_to settings_path, notice: "Configurações atualizadas com sucesso."
    else
      render :show, status: :unprocessable_entity
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

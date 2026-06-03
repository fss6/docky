class SettingsController < ApplicationController
  before_action :set_setting
  before_action :authorize_policy

  def show
  end

  private

  def set_setting
    @setting = current_user.account.setting || current_user.account.create_setting!
  end

  def authorize_policy
    authorize @setting
  end
end

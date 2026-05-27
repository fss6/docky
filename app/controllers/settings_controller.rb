class SettingsController < ApplicationController
  before_action :set_setting
  before_action :authorize_policy

  def show
    @onboarding_template_count = current_user.account.onboarding_templates.count
  end

  private

  def set_setting
    @setting = current_user.account.setting || current_user.account.create_setting!
  end

  def authorize_policy
    authorize @setting
  end
end

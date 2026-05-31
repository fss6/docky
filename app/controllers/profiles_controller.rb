# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authorize_profile

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: t("profiles.flashes.updated"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_profile
    authorize :profile, policy_class: ProfilePolicy
  end

  def profile_params
    permitted = params.require(:user).permit(:name, :email, :avatar, :remove_avatar)
    permitted.delete(:remove_avatar) if permitted[:avatar].present?
    permitted
  end
end

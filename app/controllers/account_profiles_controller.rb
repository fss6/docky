# frozen_string_literal: true

class AccountProfilesController < ApplicationController
  before_action :authorize_account_profile

  def edit
    @account = current_user.account
  end

  def update
    @account = current_user.account

    if @account.update(account_profile_params)
      redirect_to edit_account_profile_path, notice: t("account_profiles.flashes.updated"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_account_profile
    authorize :account_profile, policy_class: AccountProfilePolicy
  end

  def account_profile_params
    permitted = params.require(:account).permit(:name, :description, :contact_email, :logo, :remove_logo)
    permitted.delete(:remove_logo) if permitted[:logo].present?
    permitted
  end
end

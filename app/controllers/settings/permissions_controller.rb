# frozen_string_literal: true

module Settings
  class PermissionsController < ApplicationController
    before_action :authorize_policy

    def show
      load_show_assigns
    end

    def update
      Permissions::UpdateGrants.call(
        account: current_user.account,
        grants_params: grants_params,
        changed_by: current_user
      )
      redirect_to settings_permissions_path, notice: t("settings.permissions.flashes.updated")
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
      flash.now[:alert] = error.message
      load_show_assigns
      render :show, status: :unprocessable_entity
    end

    private

    def authorize_policy
      authorize :account_permissions, policy_class: AccountPermissionsPolicy
    end

    def load_show_assigns
      @grants_by_key = current_user.account.permission_grants
        .where(role: Permissions::Catalog::MEMBER_ROLE)
        .index_by(&:capability_key)
      @grouped_keys = Permissions::Catalog.grouped_keys
    end

    def grants_params
      permitted_keys = Permissions::Catalog.keys.map { |key| key.tr(".", "_") }
      raw = params.fetch(:grants, {}).permit(*permitted_keys)
      raw.to_h.transform_keys { |key| key.tr("_", ".") }
    end
  end
end

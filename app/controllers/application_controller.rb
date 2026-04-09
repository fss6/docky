class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, unless: :devise_controller?
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :find_current_tenant, unless: :devise_controller?
  before_action :ensure_billing_access!, unless: :devise_controller?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def find_current_tenant
    current_account = current_user.account
    set_current_tenant(current_account)
  end

  def ensure_billing_access!
    return if current_user.blank?
    return if controller_name == "billing"
    return if current_user.role_administrator?
    return if current_user.account.billing_access_granted?

    redirect_to billing_pending_path
  end
end

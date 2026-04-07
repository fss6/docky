class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, unless: :devise_controller?
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :find_current_tenant, unless: :devise_controller?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def find_current_tenant
    current_account = current_user.account
    set_current_tenant(current_account)
  end
end

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method
  after_action :verify_authorized, unless: :devise_controller?
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :find_current_tenant, unless: :devise_controller?
  before_action :set_nav_client_autocomplete_json, unless: :devise_controller?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def find_current_tenant
    current_account = current_user.account
    set_current_tenant(current_account)
  end

  def set_nav_client_autocomplete_json
    return unless current_user
    return unless policy(Client).index?

    @nav_clients_json = Client.kept.order(:name).map { |c|
      { id: c.id, name: c.name, tax_id: c.tax_id.to_s }
    }.to_json
  end

  def record_audit_event(event_type:, subject:, metadata: {})
    return unless current_user&.account

    AuditEvents::Recorder.call(
      account: current_user.account,
      user: current_user,
      event_type: event_type,
      subject: subject,
      metadata: metadata
    )
  end

  def parse_period_param(raw_period)
    return nil if raw_period.blank?

    normalized = raw_period.to_s.strip.tr("/", "-")
    Date.strptime(normalized, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end
end

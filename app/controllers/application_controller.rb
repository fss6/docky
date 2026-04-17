class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method
  after_action :verify_authorized, unless: :devise_controller?
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :find_current_tenant, unless: :devise_controller?
  before_action :assign_current_client_from_session, unless: :devise_controller?
  before_action :set_nav_client_autocomplete_json, unless: :devise_controller?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_client

  def find_current_tenant
    current_account = current_user.account
    set_current_tenant(current_account)
  end

  # Cliente ativo: ID na sessão (entre requests) + registro em Current (só nesta request).
  def assign_current_client_from_session
    tenant = ActsAsTenant.current_tenant
    unless tenant
      Current.client = nil
      return
    end

    cid = session[:current_client_id]
    if cid.blank?
      Current.client = nil
      return
    end

    client = Client.find_by(id: cid)
    if client
      Current.client = client
    else
      session.delete(:current_client_id)
      Current.client = nil
    end
  end

  def current_client
    Current.client
  end

  def set_nav_client_autocomplete_json
    return unless current_user
    return unless policy(Client).index?

    @nav_clients_json = (
      [{ id: "", name: "Todos os clientes" }] +
      Client.order(:name).map { |c| { id: c.id, name: c.name } }
    ).to_json
  end

  # Para páginas que dependem do cliente activo na sessão (sem `client_id` na URL).
  def require_current_client!
    return if current_client

    skip_authorization
    redirect_to clients_path, alert: "Selecione um cliente para continuar."
  end

  def documents_in_current_client_scope
    base = Document.all
    if current_client
      base.joins(:folder).where(folders: { client_id: current_client.id })
    else
      base
    end
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

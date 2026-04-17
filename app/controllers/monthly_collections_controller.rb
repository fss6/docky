class MonthlyCollectionsController < ApplicationController
  before_action :authorize_policy
  before_action :require_current_client!
  before_action :set_period_from_id!, only: :show
  before_action :set_collection_folder, only: :show
  before_action :set_checklist, only: :show
  before_action :set_available_documents, only: :show

  def index
    @pagy, @periods = pagy(available_periods_scope, limit: 8)
  end

  def create
    period = parse_period(params[:period])
    return redirect_to monthly_collections_path, alert: "Selecione uma competência válida." if period.nil?

    existing = CompetencyChecklist.exists?(account: current_user.account, client: current_client, period: period)
    return redirect_to monthly_collections_path, alert: "Essa competência já existe." if existing

    Checklist::BuildForCompetency.new(
      account: current_user.account,
      client: current_client,
      period: period
    ).call

    folder = Folder.find_or_create_by!(
      account: current_user.account,
      client: current_client,
      name: period.strftime("%Y-%m"),
      visible: false
    )
    record_audit_event(
      event_type: "monthly_collection.created",
      subject: folder,
      metadata: { period: period.strftime("%Y-%m"), client_id: current_client.id }
    )

    redirect_to monthly_collection_path(period.strftime("%Y-%m")), notice: "Competência criada com sucesso."
  end

  def show
    @items = @checklist ? @checklist.items.includes(:validated_by_user).order(:id) : []
  end

  private

  def authorize_policy
    authorize Folder, :index?
  end

  def set_period_from_id!
    @period = parse_period(params[:id])
    return if @period.present?

    redirect_to monthly_collections_path, alert: "Competência inválida."
  end

  def set_collection_folder
    @collection_folder = Folder.find_or_create_by!(
      account: current_user.account,
      client: current_client,
      name: @period.strftime("%Y-%m"),
      visible: false
    )
  end

  def set_checklist
    @checklist = CompetencyChecklist.find_by(
      account: current_user.account,
      client: current_client,
      period: @period
    )
    unless @checklist
      redirect_to monthly_collections_path, alert: "Competência não encontrada."
      return
    end

  end

  def set_available_documents
    @available_documents = current_user.account.documents
      .where(folder_id: @collection_folder.id)
      .with_attached_file
      .order(created_at: :desc)
  end

  def parse_period(raw_period)
    parse_period_param(raw_period)
  end

  def available_periods_scope
    CompetencyChecklist
      .where(account: current_user.account, client: current_client)
      .select(:period)
      .distinct
      .order(period: :desc)
  end
end

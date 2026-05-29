class MonthlyCollectionsController < ApplicationController
  before_action :redirect_to_clients_index
  before_action :authorize_policy
  before_action :set_period_from_id!, only: %i[show document_statuses destroy close reopen]
  before_action :set_period_record, only: %i[show document_statuses close reopen]
  before_action :set_collection_folder, only: %i[show document_statuses]
  before_action :set_checklist, only: :show
  before_action :set_available_documents, only: :show
  before_action :set_uploaded_documents, only: :show

  def index
    @pagy, @periods = pagy(available_periods_scope, limit: 8)
  end

  def create
    period = parse_period(params[:period])
    return redirect_to monthly_collections_path, alert: "Selecione uma competência válida." if period.nil?

    existing = Period.exists?(account: current_user.account, client: current_client, period: period)
    return redirect_to monthly_collections_path, alert: "Essa competência já existe." if existing

    Periods::OpenForClient.call(
      client: current_client,
      period: period,
      account: current_user.account
    )

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

  def document_statuses
    docs = uploaded_documents_scope.limit(30)
    render json: {
      documents: docs.map { |doc| document_status_payload(doc) }
    }
  end

  def close
    authorize @period_record, :close?

    if Periods::Close.call(period: @period_record, user: current_user, ip: request.remote_ip)
      redirect_to monthly_collection_path(@period.strftime("%Y-%m")),
                  notice: "Competência encerrada com sucesso.",
                  status: :see_other
    else
      redirect_to monthly_collection_path(@period.strftime("%Y-%m")),
                  alert: "Esta competência já está encerrada.",
                  status: :see_other
    end
  end

  def reopen
    authorize @period_record, :reopen?

    if Periods::Reopen.call(period: @period_record, user: current_user, ip: request.remote_ip)
      redirect_to monthly_collection_path(@period.strftime("%Y-%m")),
                  notice: "Competência reaberta com sucesso.",
                  status: :see_other
    else
      redirect_to monthly_collection_path(@period.strftime("%Y-%m")),
                  alert: "Esta competência já está aberta.",
                  status: :see_other
    end
  end

  def destroy
    checklist = Period.find_by(
      account: current_user.account,
      client: current_client,
      period: @period
    )

    unless checklist
      redirect_to monthly_collections_path, alert: "Competência não encontrada."
      return
    end

    authorize checklist, :close?
    checklist.destroy!
    redirect_to monthly_collections_path, notice: "Competência removida com sucesso."
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

  def set_period_record
    @period_record = Period.find_by(
      account: current_user.account,
      client: current_client,
      period: @period
    )
    return if @period_record.present?

    redirect_to monthly_collections_path, alert: "Competência não encontrada."
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
    @checklist = @period_record
  end

  def set_available_documents
    @available_documents = uploaded_documents_scope
  end

  def set_uploaded_documents
    @uploaded_documents = uploaded_documents_scope.limit(30)
  end

  def uploaded_documents_scope
    return Document.none if @period_record.blank?

    current_user.account.documents
      .where(period_id: @period_record.id)
      .with_attached_file
      .order(created_at: :desc)
  end

  def document_status_payload(doc)
    {
      id: doc.id,
      name: helpers.document_file_label(doc),
      status: doc.status,
      status_label: helpers.document_status_label(doc.status),
      status_badge_classes: helpers.document_status_badge_classes(doc.status),
      created_at_label: I18n.l(doc.created_at, format: :short),
      show_path: document_path(doc)
    }
  end

  def parse_period(raw_period)
    parse_period_param(raw_period)
  end

  def available_periods_scope
    Period
      .where(account: current_user.account, client: current_client)
      .order(period: :desc)
  end
end

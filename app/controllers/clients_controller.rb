# frozen_string_literal: true

class ClientsController < ApplicationController

  before_action :set_client, only: %i[show edit update archive unarchive summary]
  before_action :ensure_client_writable!, only: %i[edit update]
  before_action :ensure_client_kept!, only: :archive
  before_action :ensure_client_archived!, only: :unarchive
  before_action :authorize_policy
  before_action :ensure_period_in_url, only: :show, unless: :onboarding_show?
  before_action :load_monthly_context, only: %i[show summary], unless: :onboarding_show?
  before_action :load_onboarding_context, only: :show, if: :onboarding_show?

  def index
    assign_index_filter_params
    scope = Client.filtered_by_index_params(params)
    @account_has_clients = Client.exists?
    @pagy, @clients = pagy(index_clients_order(scope), limit: 10)
  end

  def show
    if onboarding_show?
      render :show_onboarding
    else
      load_tab_content
    end
  end

  def summary
    if @period_record.blank?
      render json: { period_exists: false, period: @period.strftime("%Y-%m") }, status: :not_found
      return
    end

    render json: @summary
  end

  def new
    @client = Client.new
    load_onboarding_template_counts
  end

  def edit
  end

  def create
    @client = Client.new(client_params)
    onboarding_kind = params.fetch(:onboarding_kind, "new_client")

    respond_to do |format|
      begin
        Clients::CreateWithOnboarding.call(
          client: @client,
          onboarding_kind: onboarding_kind,
          user: current_user
        )
        notice = if @client.onboarding?
                   "Cliente cadastrado. Onboarding iniciado."
                 else
                   "Cliente criado com sucesso."
                 end
        format.html { redirect_to @client, notice: notice }
        format.json { render :show, status: :created, location: @client }
      rescue ActiveRecord::RecordInvalid
        load_onboarding_template_counts
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to @client, notice: "Cliente atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def archive
    authorize @client, :archive?

    Clients::Archive.call(
      client: @client,
      user: current_user,
      clear_session: method(:clear_current_client_session)
    )

    redirect_to clients_path, notice: t("clients.archive.notice"), status: :see_other
  end

  def unarchive
    authorize @client, :unarchive?

    Clients::Unarchive.call(client: @client, user: current_user)

    redirect_to @client, notice: t("clients.unarchive.notice"), status: :see_other
  end

  private

  def ensure_client_writable!
    return unless @client.archived?

    redirect_to @client, alert: t("clients.archived.mutation_blocked"), status: :see_other
  end

  def ensure_client_kept!
    return if @client.kept?

    redirect_to @client, alert: t("clients.archived.already_archived"), status: :see_other
  end

  def ensure_client_archived!
    return if @client.archived?

    redirect_to @client, alert: t("clients.archived.not_archived"), status: :see_other
  end

  def clear_current_client_session(client)
    return unless session[:current_client_id].to_i == client.id

    session.delete(:current_client_id)
    Current.client = nil
  end

  def authorize_policy
    authorize(@client || Client)
  end

  def set_client
    @client = Client.find(params.expect(:id))
  end

  def load_monthly_context
    @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
    @active_tab = ClientsHelper::VALID_TABS.include?(params[:aba].to_s) ? params[:aba].to_s : "documentos"

    @monthly = Clients::EnsureMonthlyCollection.call(
      client: @client,
      period: @period,
      create_if_missing: false
    )
    @period_record = @monthly.period_record
    @checklist = @monthly.checklist
    @folder_shim = @monthly.folder_shim
    @summary = Clients::MonthlySummary.new(
      client: @client,
      checklist: @checklist,
      period: @period,
      period_record: @period_record
    ).call
    @period_phase = @summary[:period_phase]

    if @period_record.present?
      @checklist_items = @checklist.items.includes(:last_document, :validated_by_user).order(:id)
      @linked_items_by_document_id = @checklist_items.select { |i| i.last_document_id.present? }.index_by(&:last_document_id)
      @pending_link_items = @checklist_items.select(&:awaiting_receipt?)
      @upload_invites = UploadInvite.where(client: @client, period: @period).newest_first
      @active_upload_invite = @upload_invites.find(&:active?)
    else
      @checklist_items = []
      @linked_items_by_document_id = {}
      @pending_link_items = []
      @upload_invites = []
      @active_upload_invite = nil
    end

    @template_items_count = @client.client_checklist_items.active_only.count
  end

  def ensure_period_in_url
    return if params[:period].present? && parse_period_param(params[:period]).present?

    redirect_params = { period: Date.current.strftime("%Y-%m") }
    redirect_params[:aba] = params[:aba] if params[:aba].present?
    redirect_to client_path(@client, redirect_params), status: :see_other
  end

  def load_tab_content
    return if @period_record.blank?

    case @active_tab
    when "documentos"
      load_documents_tab
    when "historico"
      load_history_tab
    end
  end

  def load_documents_tab
    scope = @monthly.documents_scope.with_attached_file.order(created_at: :desc)
    @pagy, @documents = pagy(scope, limit: 30)
    @category_counts = scope.to_a.group_by { |d| heuristic_category_for(d) }.transform_values(&:size)
  end

  def load_history_tab
    @period_activity = Clients::PeriodActivityTimeline.call(
      client: @client,
      period: @period,
      period_record: @period_record,
      limit: Clients::PeriodActivityTimeline::TAB_LIMIT
    )
  end

  def heuristic_category_for(document)
    return "outros" unless document.file.attached?

    filename = document.file.filename.to_s.downcase
    content_type = document.file.content_type.to_s.downcase
    if filename.end_with?(".xml") || content_type.include?("xml")
      "nfe"
    elsif filename.end_with?(".pdf") || content_type == "application/pdf"
      "extrato"
    elsif content_type.start_with?("image/")
      "comprovante"
    else
      "outros"
    end
  end

  def assign_index_filter_params
    @search_query = params[:q].to_s.strip
    @selected_status = params[:status].to_s
  end

  def index_clients_order(scope)
    scope.order(:name)
  end

  def client_params
    params.expect(client: [:name, :tax_id, :email, :phone, :notes, :monthly_deadline_day])
  end

  def onboarding_show?
    @client&.onboarding?
  end

  def load_onboarding_context
    @onboarding_checklist = @client.onboarding_checklist
    @onboarding_progress = Onboarding::Progress.call(checklist: @onboarding_checklist) if @onboarding_checklist
    @onboarding_items = @onboarding_checklist&.items&.ordered&.includes(:last_document, :validated_by_user) || []
    @active_onboarding_invite = UploadInvite.purpose_onboarding.where(client: @client).newest_first.find(&:active?)
  end

  def load_onboarding_template_counts
    @onboarding_template_counts = OnboardingTemplate.ordered.each_with_object({}) do |template, counts|
      counts[template.kind] = template.items.count
    end
  end
end

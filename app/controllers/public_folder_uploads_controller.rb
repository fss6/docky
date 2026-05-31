class PublicFolderUploadsController < ApplicationController
  layout "public_upload"

  skip_before_action :authenticate_user!
  skip_before_action :find_current_tenant
  skip_before_action :set_nav_client_autocomplete_json
  skip_after_action :verify_authorized

  before_action :resolve_upload_target!, except: %i[onboarding onboarding_upload onboarding_extra_upload]
  before_action :resolve_onboarding_invite!, only: %i[onboarding onboarding_upload onboarding_extra_upload]
  before_action :ensure_client_not_archived_for_public!, only: %i[show create onboarding onboarding_upload onboarding_extra_upload]
  before_action :ensure_period_allows_upload!, only: %i[show create]
  before_action :ensure_public_upload_enabled!, only: %i[show create]
  before_action :ensure_onboarding_invite_active!, only: %i[onboarding onboarding_upload onboarding_extra_upload]
  before_action :set_account_tenant
  before_action :track_invite_access, only: %i[show onboarding]

  def show
    load_monthly_portal_context
    @document = @folder.documents.build
  end

  def create
    guard = Periods::UploadGuard.call(period: @period_record)
    unless guard.allowed
      load_monthly_portal_context
      flash.now[:alert] = public_upload_blocked_alert(guard)
      @document = @folder.documents.build
      return render :show, status: :unprocessable_entity
    end

    @document = @folder.documents.build(upload_params)
    Documents::AssignToPeriod.call(
      document: @document,
      period_record: @period_record,
      folder: @folder,
      user_id: upload_owner_user&.id,
      metadata: public_upload_metadata
    )

    if @document.save
      AuditEvents::RecordDocumentReceived.call(
        document: @document,
        user: upload_owner_user
      )
      Documents::ProcessAfterUpload.call(
        document: @document,
        file_io: params.dig(:document, :file)
      )
      redirect_to public_folder_upload_path(token: @upload_token),
                  notice: "Arquivo enviado com sucesso.",
                  status: :see_other
    else
      load_monthly_portal_context
      flash.now[:alert] = @document.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def onboarding
    load_onboarding_portal_context
    @selected_item = @onboarding_items.find { |i| i.id == params[:item_id].to_i } if params[:item_id].present?
    @selected_item ||= @onboarding_items.find(&:pending?)
  end

  def onboarding_upload
    item = @client.onboarding_checklist.items.find(params.expect(:onboarding_checklist_item_id))
    file = params.dig(:document, :file)

    unless file.present?
      redirect_to public_onboarding_upload_path(token: @upload_token, item_id: item.id),
                  alert: "Selecione um arquivo.",
                  status: :see_other
      return
    end

    Onboarding::ReceiveDocument.call(
      item: item,
      file: file,
      client: @client,
      account: @upload_invite.account,
      upload_owner_user: upload_owner_user
    )

    redirect_to public_onboarding_upload_path(token: @upload_token),
                notice: "Documento enviado com sucesso.",
                status: :see_other
  rescue ActiveRecord::RecordNotFound
    redirect_to public_onboarding_upload_path(token: @upload_token), alert: "Item não encontrado."
  end

  def onboarding_extra_upload
    file = params.dig(:document, :file)
    unless file.present?
      redirect_to public_onboarding_upload_path(token: @upload_token), alert: "Selecione um arquivo."
      return
    end

    folder = ensure_client_folder!
    document = folder.documents.build
    document.file.attach(file)
    document.assign_attributes(
      account_id: @account.id,
      user_id: upload_owner_user&.id,
      status: :pending
    )
    document.metadata = {
      "upload_source" => "onboarding_extra",
      "uploaded_via_token" => true
    }
    document.save!
    AuditEvents::RecordDocumentReceived.call(document: document, user: upload_owner_user)
    Documents::ProcessAfterUpload.call(document: document, file_io: file)

    redirect_to public_onboarding_upload_path(token: @upload_token),
                notice: "Documento extra recebido. Sua contabilidade irá analisá-lo.",
                status: :see_other
  end

  private

  def resolve_upload_target!
    @upload_invite = UploadInvite.find_by(token: params[:token])
    if @upload_invite
      @client = @upload_invite.client
      if @upload_invite.onboarding?
        redirect_to public_onboarding_upload_path(token: @upload_invite.token), status: :see_other
        return
      end

      if @client.onboarding?
        onboarding_invite = UploadInvite.purpose_onboarding.where(client: @client).newest_first.find(&:active?)
        @onboarding_redirect_url = onboarding_invite ? public_onboarding_upload_path(token: onboarding_invite.token) : nil
        @expired_message = "Sua conta ainda está em configuração. Termine o onboarding primeiro."
        return render :onboarding_required, status: :forbidden
      end

      @period = @upload_invite.period
      @upload_token = @upload_invite.token
      monthly = Clients::EnsureMonthlyCollection.call(
        client: @client,
        period: @period,
        account: @upload_invite.account,
        create_if_missing: false
      )
      @period_record = monthly.period_record
      @folder = monthly.folder_shim
      return
    end

    @folder = Folder.includes(:account, :client).find_by(public_upload_token: params[:token])
    if @folder.present?
      if @folder.visible?
        @expired_message = "Este link não está mais disponível."
        return render_expired_link(status: :gone)
      end

      @upload_token = @folder.public_upload_token
      @client = @folder.client
      @period = Date.strptime(@folder.name, "%Y-%m").beginning_of_month if @folder.name.to_s.match?(/\A\d{4}-\d{2}\z/)
      @period ||= Date.current.beginning_of_month
      if @client.present?
        monthly = Clients::EnsureMonthlyCollection.call(
          client: @client,
          period: @period,
          account: @folder.account
        )
        @period_record = monthly.period_record
      end
      return
    end

    @upload_token = params[:token]
    render_expired_link(status: :not_found)
  end

  def resolve_onboarding_invite!
    @upload_invite = UploadInvite.purpose_onboarding.find_by(token: params[:token])
    unless @upload_invite&.active?
      @expired_message = "Este link de onboarding não está mais disponível."
      return render_expired_link(status: :gone)
    end

    @client = @upload_invite.client
    @upload_token = @upload_invite.token
    @account = @upload_invite.account
  end

  def ensure_onboarding_invite_active!
    return unless performed?

    render_expired_link(status: :gone) unless @upload_invite&.active?
  end

  def load_onboarding_portal_context
    @checklist = @client.onboarding_checklist
    @onboarding_items = @checklist&.items&.ordered || []
    @progress = @checklist ? Onboarding::Progress.call(checklist: @checklist) : nil
  end

  def ensure_period_allows_upload!
    return if performed?

    if @period_record.blank?
      @blocked_message = PublicUploads::BlockedMessage.for(kind: :period_missing)
      load_portal_account
      return render :unavailable, status: :ok
    end

    guard = Periods::UploadGuard.call(period: @period_record)
    return if guard.allowed

    @blocked_message = PublicUploads::BlockedMessage.for(kind: :period_closed, period: @period)
    load_portal_account
    render :unavailable, status: :ok
  end

  def load_portal_account
    @portal_account = @upload_invite&.account || @folder&.account
  end

  def load_monthly_portal_context
    @period_label = PeriodFormatting.display_label(@period) if @period.present?
    load_portal_account
    @pending_checklist_items = @period_record&.items&.select(&:awaiting_receipt?) || []
    @recent_public_documents = recent_public_documents
  end

  def public_upload_blocked_alert(guard)
    if @period_record&.closed? || guard.reason.to_s.include?("encerrada")
      PublicUploads::BlockedMessage.for(kind: :period_closed, period: @period)
    else
      guard.reason
    end
  end

  def set_account_tenant
    account = @upload_invite&.account || @folder&.account
    set_current_tenant(account) if account
  end

  def upload_owner_user
    account = @upload_invite&.account || @folder&.account
    @upload_owner_user ||= account&.users&.role_owner&.first || account&.users&.first
  end

  def upload_params
    params.expect(document: [:file])
  end

  def recent_public_documents
    scope = if @period_record
              Document.for_period(@period_record)
            elsif @upload_invite
              Document.for_client_period(@client, @period)
            else
              @folder.documents
            end

    scope
      .with_attached_file
      .where("documents.metadata ->> 'upload_source' = ?", "public_link")
      .order(created_at: :desc)
      .limit(10)
  end

  def public_upload_metadata
    {
      "upload_source" => "public_link",
      "uploaded_via_token" => true
    }
  end

  def ensure_public_upload_enabled!
    return if performed?
    return if @upload_invite&.active?
    return if @folder&.public_upload_enabled?

    render_expired_link(status: :gone)
  end

  def track_invite_access
    @upload_invite&.record_access!
  end

  def ensure_client_not_archived_for_public!
    return if performed?
    return unless @client&.archived?

    @expired_message = I18n.t("clients.archived.public_upload_blocked")
    render_expired_link(status: :gone)
  end

  def render_expired_link(status:)
    render :expired, status: status
  end

  def ensure_client_folder!
    folder = @client.folders.visible.first
    return folder if folder

    Folder.create!(
      account: @account,
      client: @client,
      name: "Documentos",
      visible: true
    )
  end
end

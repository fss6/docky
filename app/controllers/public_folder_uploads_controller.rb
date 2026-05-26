class PublicFolderUploadsController < ApplicationController
  layout "public_upload"

  skip_before_action :authenticate_user!
  skip_before_action :find_current_tenant
  skip_before_action :assign_current_client_from_session
  skip_before_action :set_nav_client_autocomplete_json
  skip_after_action :verify_authorized

  before_action :resolve_upload_target!
  before_action :ensure_period_allows_upload!
  before_action :ensure_public_upload_enabled!
  before_action :set_account_tenant
  before_action :track_invite_access, only: :show

  def show
    @document = @folder.documents.build
    @recent_public_documents = recent_public_documents
  end

  def create
    guard = Periods::UploadGuard.call(period: @period_record)
    unless guard.allowed
      flash.now[:alert] = guard.reason
      @recent_public_documents = recent_public_documents
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
      DocumentOcrJob.perform_later(@document.id) if @document.file.attached?
      redirect_to public_folder_upload_path(token: @upload_token),
                  notice: "Arquivo enviado com sucesso.",
                  status: :see_other
    else
      @recent_public_documents = recent_public_documents
      flash.now[:alert] = @document.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

  def resolve_upload_target!
    @upload_invite = UploadInvite.find_by(token: params[:token])
    if @upload_invite
      @client = @upload_invite.client
      @period = @upload_invite.period
      @upload_token = @upload_invite.token
      monthly = Clients::EnsureMonthlyCollection.call(
        client: @client,
        period: @period,
        account: @upload_invite.account
      )
      @period_record = monthly.period_record
      @folder = monthly.folder_shim
      return
    end

    @folder = Folder.includes(:account, :client).find_by(public_upload_token: params[:token])
    if @folder.present?
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

  def ensure_period_allows_upload!
    return if performed?
    return if @period_record.blank?

    guard = Periods::UploadGuard.call(period: @period_record)
    return if guard.allowed

    @upload_blocked_reason = guard.reason
    render_expired_link(status: :gone)
  end

  def set_account_tenant
    set_current_tenant(@folder.account)
  end

  def upload_owner_user
    @upload_owner_user ||= @folder.account.users.role_owner.first || @folder.account.users.first
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

  def render_expired_link(status:)
    @expired_message = @upload_blocked_reason if @upload_blocked_reason.present?
    render :expired, status: status
  end
end

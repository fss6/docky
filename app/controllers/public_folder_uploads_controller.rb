class PublicFolderUploadsController < ApplicationController
  layout "public_upload"

  skip_before_action :authenticate_user!
  skip_before_action :find_current_tenant
  skip_before_action :assign_current_client_from_session
  skip_before_action :set_nav_client_autocomplete_json
  skip_after_action :verify_authorized

  before_action :set_folder
  before_action :ensure_public_upload_enabled!
  before_action :set_account_tenant

  def show
    @document = @folder.documents.build
    @recent_public_documents = recent_public_documents
  end

  def create
    @document = @folder.documents.build(upload_params)
    @document.assign_attributes(
      account_id: @folder.account_id,
      user_id: upload_owner_user&.id,
      status: :pending,
      metadata: public_upload_metadata
    )

    if @document.save
      DocumentOcrJob.perform_later(@document.id) if @document.file.attached?
      redirect_to public_folder_upload_path(token: @folder.public_upload_token),
                  notice: "Arquivo enviado com sucesso.",
                  status: :see_other
    else
      @recent_public_documents = recent_public_documents
      flash.now[:alert] = @document.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_folder
    @folder = Folder.includes(:account).find_by(public_upload_token: params[:token])
    return if @folder.present?

    render_expired_link(status: :not_found)
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
    @folder.documents
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
    return if @folder.public_upload_enabled?

    render_expired_link(status: :gone)
  end

  def render_expired_link(status:)
    render :expired, status: status
  end
end

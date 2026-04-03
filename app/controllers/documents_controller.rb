class DocumentsController < ApplicationController
  before_action :set_folder, only: %i[index create]
  before_action :set_document, only: %i[show destroy]

  def index
    @documents = @folder.documents.includes(:account, :user, :folder).with_attached_file.order(created_at: :desc)
  end

  def show
  end

  def create
    @document = @folder.documents.build
    assign_defaults_for_upload!(@document)
    @document.assign_attributes(upload_params)

    respond_to do |format|
      if @document.save
        DocumentOcrJob.perform_later(@document.id) if @document.file.attached?

        format.html { redirect_to after_upload_path, notice: "Arquivo enviado com sucesso." }
        format.json { render :show, status: :created, location: @document }
      else
        format.html do
          redirect_to after_upload_path, alert: @document.errors.full_messages.to_sentence
        end
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    folder = @document.folder
    @document.destroy!

    respond_to do |format|
      format.html { redirect_to folder_documents_path(folder), notice: "Documento excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_folder
    @folder = Folder.find(params.expect(:folder_id))
  end

  def set_document
    @document = Document.includes(:account, :user, :folder).with_attached_file.find(params.expect(:id))
  end

  # Preenchimento automático: conta da pasta, primeiro usuário dessa conta, status pendente.
  # Para forçar Account.first global, troque `account` por `Account.order(:id).first`
  # e garanta que a pasta pertença a essa conta.
  def assign_defaults_for_upload!(doc)
    account = @folder.account
    user = account&.users&.order(:id)&.first

    doc.assign_attributes(
      account_id: account&.id,
      user_id: user&.id,
      status: :pending
    )
  end

  def upload_params
    params.expect(document: [:file])
  end

  def after_upload_path
    params[:upload_context].to_s == "folder" ? folder_path(@folder) : folder_documents_path(@folder)
  end
end

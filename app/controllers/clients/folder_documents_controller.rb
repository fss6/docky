# frozen_string_literal: true

module Clients
  class FolderDocumentsController < BaseController
    include PastasTabData

    before_action :set_client
    before_action :set_folder
    before_action :set_document, only: :destroy
    before_action :authorize_folder
    before_action :authorize_document, only: :destroy

    def create
      @document = @folder.documents.build
      assign_defaults_for_upload!(@document)
      @document.assign_attributes(document_params)
      @period_param = pastas_period_param

      respond_to do |format|
        if @document.save
          AuditEvents::RecordDocumentReceived.call(
            document: @document,
            user: current_user,
            ip: request.remote_ip
          )
          DocumentOcrJob.perform_later(@document.id) if @document.file.attached?
          load_folder_documents
          load_folders_for_pastas_tab
          flash.now[:notice] = "Arquivo enviado com sucesso."
          format.turbo_stream { render :create }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                        notice: "Arquivo enviado com sucesso.",
                        status: :see_other
          end
        else
          flash.now[:alert] = @document.errors.full_messages.to_sentence
          format.turbo_stream { render :create, status: :unprocessable_entity }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                        alert: @document.errors.full_messages.to_sentence,
                        status: :see_other
          end
        end
      end
    end

    def destroy
      @period_param = pastas_period_param
      Wiki::CleanupDocumentService.new(account: @document.account, document_id: @document.id).call
      @document.destroy!
      load_folder_documents
      load_folders_for_pastas_tab
      flash.now[:notice] = "Arquivo removido com sucesso."

      respond_to do |format|
        format.turbo_stream { render :destroy }
        format.html do
          redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                      notice: "Arquivo removido com sucesso.",
                      status: :see_other
        end
      end
    end

    private

    def authorize_folder
      authorize @folder, :show?
    end

    def authorize_document
      authorize @document, :destroy?
    end

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def set_folder
      @folder = @client.folders.visible.find(params.expect(:folder_id))
    end

    def set_document
      @document = @folder.documents.find(params.expect(:id))
    end

    def document_params
      params.expect(document: [:file])
    end

    def pastas_period_param
      params[:period].presence || Date.current.strftime("%Y-%m")
    end

    def load_folder_documents
      @documents = @folder.documents.with_attached_file.includes(:user).order(created_at: :desc).limit(100)
    end

    def assign_defaults_for_upload!(document)
      document.assign_attributes(
        account_id: @folder.account_id,
        user_id: current_user.id,
        status: :pending,
        client_id: @folder.client_id,
        collection_period: nil
      )

      meta = (document.metadata || {}).dup
      meta["upload_source"] = "account_upload"
      document.metadata = meta
    end
  end
end

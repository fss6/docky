# frozen_string_literal: true

module Clients
  class FoldersController < BaseController
    include PastasTabData

    before_action :set_client
    before_action :set_folder, only: %i[show update destroy]
    before_action :authorize_policy

    def index
      redirect_to client_path(@client, aba: "pastas", period: pastas_period_param), status: :see_other
    end

    def show
      load_folder_documents
      @period_param = pastas_period_param

      if folder_drawer_frame_request?
        render partial: "clients/folders/drawer", layout: false
      else
        redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                    status: :see_other
      end
    end

    def drawer_empty
      @period_param = pastas_period_param
      render :drawer_empty, layout: false
    end

    def create
      @folder = @client.folders.build(folder_params)
      @folder.visible = true
      @period_param = pastas_period_param

      respond_to do |format|
        if @folder.save
          load_folders_for_pastas_tab
          flash.now[:notice] = "Pasta criada com sucesso."
          format.turbo_stream { render :create }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: pastas_period_param),
                        notice: "Pasta criada com sucesso.",
                        status: :see_other
          end
          format.json { render json: @folder, status: :created, location: client_folder_path(@client, @folder) }
        else
          @period_param = pastas_period_param
          flash.now[:alert] = @folder.errors.full_messages.to_sentence
          format.turbo_stream { render :create, status: :unprocessable_entity }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: @period_param),
                        alert: @folder.errors.full_messages.to_sentence,
                        status: :see_other
          end
          format.json { render json: @folder.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      @period_param = pastas_period_param

      respond_to do |format|
        if @folder.update(folder_params)
          load_folder_documents
          load_folders_for_pastas_tab
          flash.now[:notice] = "Pasta atualizada com sucesso."
          format.turbo_stream { render :update }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                        notice: "Pasta atualizada com sucesso.",
                        status: :see_other
          end
          format.json { render json: @folder, status: :ok, location: client_folder_path(@client, @folder) }
        else
          flash.now[:alert] = @folder.errors.full_messages.to_sentence
          format.turbo_stream { render :update, status: :unprocessable_entity }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                        alert: @folder.errors.full_messages.to_sentence,
                        status: :see_other
          end
          format.json { render json: @folder.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @period_param = pastas_period_param

      unless @folder.empty_for_destroy?
        flash.now[:alert] = t("folders.destroy_blocked_with_documents")
        respond_to do |format|
          format.turbo_stream { render :destroy, status: :unprocessable_entity }
          format.html do
            redirect_to client_path(@client, aba: "pastas", period: @period_param, folder_id: @folder.id),
                        alert: t("folders.destroy_blocked_with_documents"),
                        status: :see_other
          end
          format.json { render json: { error: t("folders.destroy_blocked_with_documents") }, status: :unprocessable_entity }
        end
        return
      end

      @folder.destroy!
      load_folders_for_pastas_tab

      respond_to do |format|
        format.turbo_stream { render :destroy }
        format.html do
          redirect_to client_path(@client, aba: "pastas", period: @period_param),
                      notice: "Pasta excluída com sucesso.",
                      status: :see_other
        end
        format.json { head :no_content }
      end
    end

    private

    def authorize_policy
      authorize Folder
    end

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def set_folder
      @folder = @client.folders.visible.includes(:account, :client).find(params.expect(:id))
    end

    def folder_params
      params.expect(folder: [:name])
    end

    def pastas_period_param
      params[:period].presence || Date.current.strftime("%Y-%m")
    end

    def load_folder_documents
      @documents = @folder.documents.with_attached_file.includes(:user).order(created_at: :desc).limit(100)
    end

    def folder_drawer_frame_request?
      turbo_frame_request_id == "folder_drawer"
    end
  end
end

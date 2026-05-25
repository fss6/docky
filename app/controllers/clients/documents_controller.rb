# frozen_string_literal: true

module Clients
  class DocumentsController < ApplicationController
    before_action :set_client
    before_action :set_period
    before_action :set_monthly
    before_action :set_document, only: %i[link unlink]

    def index
      authorize @client, :show?
      scope = @monthly.documents_scope.with_attached_file.order(created_at: :desc)
      @pagy, @documents = pagy(scope, limit: 30)
      load_checklist_link_context

      respond_to do |format|
        format.html { render partial: "clients/documents/list", layout: false }
        format.turbo_stream
      end
    end

    def create
      authorize @client, :show?

      @document = @monthly.folder_shim.documents.build(upload_params)
      assign_internal_upload_defaults!

      if @document.save
        DocumentOcrJob.perform_later(@document.id) if @document.file.attached?
        flash.now[:notice] = "Documento adicionado com sucesso."
        load_checklist_link_context
        respond_to do |format|
          format.turbo_stream { render :create }
          format.html do
            redirect_to client_path(@client, aba: "documentos", period: @period.strftime("%Y-%m")),
                        notice: "Documento adicionado com sucesso.",
                        status: :see_other
          end
        end
      else
        flash.now[:alert] = @document.errors.full_messages.to_sentence
        load_checklist_link_context
        respond_to do |format|
          format.turbo_stream { render :create, status: :unprocessable_entity }
          format.html do
            redirect_to client_path(@client, aba: "documentos", period: @period.strftime("%Y-%m")),
                        alert: @document.errors.full_messages.to_sentence,
                        status: :see_other
          end
        end
      end
    end

    def link
      authorize @client, :show?
      item = @monthly.checklist.items.find(params[:item_id])

      if params[:new_item_name].present?
        item = @monthly.checklist.items.create!(
          name_snapshot: params[:new_item_name].to_s.strip,
          state: :pending
        )
        record_audit_event(
          event_type: "checklist_item.created_from_document",
          subject: item,
          metadata: { client_id: @client.id, period: @period.strftime("%Y-%m"), ip: request.remote_ip }
        )
      end

      if Clients::LinkDocument.call(document: @document, item: item, user: current_user, ip: request.remote_ip)
        @document.reload
        load_checklist_link_context
        flash.now[:notice] = "Documento vinculado."
        render_link_update
      else
        flash.now[:alert] = "Não foi possível vincular."
        render_link_update(status: :unprocessable_entity)
      end
    end

    def unlink
      authorize @client, :show?
      item = @monthly.checklist.items.find_by!(last_document_id: @document.id)
      Clients::UnlinkDocument.call(item: item, user: current_user, ip: request.remote_ip)
      @document.reload
      load_checklist_link_context
      flash.now[:notice] = "Documento desvinculado."
      render_link_update
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def set_period
      @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
    end

    def set_monthly
      @monthly = Clients::EnsureMonthlyCollection.call(client: @client, period: @period)
    end

    def set_document
      @document = @monthly.documents_scope.with_attached_file.find(params.expect(:id))
    end

    def load_checklist_link_context
      @checklist = @monthly.checklist
      @checklist_items = @checklist.items.includes(:last_document).order(:id)
      @linked_items_by_document_id = @checklist_items
        .select { |i| i.last_document_id.present? }
        .index_by(&:last_document_id)
      @pending_link_items = @checklist_items.select { |i| i.last_document_id.blank? }
      @summary = Clients::MonthlySummary.new(client: @client, checklist: @checklist, period: @period).call
      @period_param = @period.strftime("%Y-%m")
      load_visible_documents_for_cards
    end

    def load_visible_documents_for_cards
      scope = @monthly.documents_scope.with_attached_file.order(created_at: :desc)
      @pagy, @documents = pagy(scope, limit: 30, page: params[:page])
      @category_counts = scope.to_a.group_by { |document| heuristic_category_for(document) }.transform_values(&:size)
    end

    def assign_internal_upload_defaults!
      folder = @monthly.folder_shim
      @document.assign_attributes(
        account_id: folder.account_id,
        user_id: current_user.id,
        status: :pending,
        client_id: @client.id,
        collection_period: @period,
        metadata: { "upload_source" => "internal_upload" }
      )
    end

    def upload_params
      params.expect(document: [:file])
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

    def render_link_update(status: :ok)
      respond_to do |format|
        format.turbo_stream { render :link_update, status: status }
        format.html do
          redirect_to client_path(@client, aba: "documentos", period: @period_param),
                      flash: flash.to_hash,
                      status: :see_other
        end
      end
    end
  end
end

class DocumentsController < ApplicationController
  before_action :set_folder, only: %i[index create]
  before_action :set_document, only: %i[show destroy move add_tag replace_tag remove_tag]
  before_action :authorize_policy

  def index
    @documents = @folder.documents.includes(:account, :user, :folder, :embedding_records).with_attached_file.order(created_at: :desc)
  end

  def show
  end

  def tags_search
    @available_tags = documents_in_current_client_scope.pluck(:tags)
      .flatten
      .compact
      .map { |tag| tag.to_s.strip }
      .reject(&:blank?)
      .uniq
      .sort

    @selected_tags = Array(params[:tags])
      .map { |tag| tag.to_s.strip }
      .reject(&:blank?)
      .uniq

    @documents = documents_in_current_client_scope.includes(:user, :folder).with_attached_file.order(created_at: :desc)

    if @selected_tags.any?
      @selected_tags.each do |tag|
        @documents = @documents.where(
          "EXISTS (SELECT 1 FROM jsonb_array_elements_text(documents.tags) AS t(value) WHERE LOWER(t.value) = LOWER(?))",
          tag
        )
      end
    else
      @documents = @documents.none
    end
    @documents = @documents.limit(50)
  end

  def term_search
    @query = params[:q].to_s.strip
    @documents = documents_in_current_client_scope.includes(:user, :folder).with_attached_file.order(created_at: :desc)

    if @query.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      @documents = @documents.where(
        "documents.content ILIKE :q OR documents.summary ILIKE :q OR EXISTS (SELECT 1 FROM jsonb_array_elements_text(documents.tags) AS t(value) WHERE t.value ILIKE :q)",
        q: like
      )
    else
      @documents = @documents.none
    end

    @documents = @documents.limit(50)
  end

  def create
    if monthly_collection_bank_statement_upload? && selected_statement_institution.blank?
      redirect_back fallback_location: after_upload_path,
                    alert: "Selecione a instituição do extrato.",
                    status: :see_other
      return
    end

    @document = @folder.documents.build
    assign_defaults_for_upload!(@document)
    @document.assign_attributes(upload_params)

    respond_to do |format|
      if @document.save
        DocumentOcrJob.perform_later(@document.id) if @document.file.attached?
        enqueue_bank_statement_import! if monthly_collection_bank_statement_upload?

        format.html do
          redirect_back fallback_location: after_upload_path,
                        notice: "Arquivo enviado com sucesso.",
                        status: :see_other
        end
        format.json { render :show, status: :created, location: @document }
      else
        format.html do
          redirect_back fallback_location: after_upload_path,
                        alert: @document.errors.full_messages.to_sentence,
                        status: :see_other
        end
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    folder = @document.folder
    Wiki::CleanupDocumentService.new(account: @document.account, document_id: @document.id).call
    @document.destroy!

    respond_to do |format|
      format.html { redirect_to folder_documents_path(folder), notice: "Documento excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def move
    destination_folder = Folder.for_nav_client(current_client).find(params.expect(:folder_id))
    source_folder_id = @document.folder_id
    @document.update!(folder: destination_folder)
    record_audit_event(
      event_type: "document.moved",
      subject: @document,
      metadata: { from_folder_id: source_folder_id, to_folder_id: destination_folder.id }
    )
    respond_to do |format|
      format.html do
        redirect_back fallback_location: folders_path(folder_id: destination_folder.id),
                      notice: "Arquivo movido com sucesso."
      end
      format.json { render json: { ok: true, folder_id: destination_folder.id } }
    end
  end

  def add_tag
    tags = Document.normalize_tags(@document.tags + [params[:tag]])
    return redirect_back(fallback_location: document_path(@document), alert: "Informe uma tag válida.") if tags == @document.tags

    @document.update!(tags: tags)
    record_audit_event(
      event_type: "document.tag_added",
      subject: @document,
      metadata: { tag: params[:tag].to_s }
    )

    redirect_back fallback_location: document_path(@document), notice: "Tag adicionada com sucesso."
  end

  def replace_tag
    old_tag = params[:old_tag].to_s
    new_tag = params[:new_tag].to_s
    return redirect_back(fallback_location: document_path(@document), alert: "Informe a tag atual.") if old_tag.blank?
    return redirect_back(fallback_location: document_path(@document), alert: "Informe um novo valor para a tag.") if new_tag.blank?

    updated = @document.tags.reject { |tag| tag.casecmp(old_tag).zero? }
    updated << new_tag
    @document.update!(tags: Document.normalize_tags(updated))
    record_audit_event(
      event_type: "document.tag_replaced",
      subject: @document,
      metadata: { old_tag: old_tag, new_tag: new_tag }
    )

    redirect_back fallback_location: document_path(@document), notice: "Tag atualizada com sucesso."
  end

  def remove_tag
    tag_to_remove = params[:tag].to_s
    tags = @document.tags.reject { |tag| tag.casecmp(tag_to_remove).zero? }
    @document.update!(tags: tags)
    record_audit_event(
      event_type: "document.tag_removed",
      subject: @document,
      metadata: { tag: tag_to_remove }
    )

    redirect_back fallback_location: document_path(@document), notice: "Tag removida com sucesso."
  end

  private

  def authorize_policy
    record = @document || Document
    authorize record
  end

  def set_folder
    @folder = Folder.for_nav_client(current_client).find(params.expect(:folder_id))
  end

  def set_document
    @document = documents_in_current_client_scope
      .includes(:account, :user, :folder, :embedding_records)
      .with_attached_file
      .find(params.expect(:id))
  end

  # Preenchimento automático: conta da pasta, usuário logado, status pendente.
  def assign_defaults_for_upload!(doc)
    account = @folder.account
    user = current_user

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
    return monthly_collection_path(upload_period.strftime("%Y-%m")) if monthly_collection_upload?
    return folder_competency_checklist_path(@folder, period: upload_period.strftime("%Y-%m")) if competency_checklist_upload?
    return folder_path(@folder) if params[:upload_context].to_s == "folder"

    folder_documents_path(@folder)
  end

  def competency_checklist_upload?
    params[:upload_context].to_s == "competency_checklist"
  end

  def monthly_collection_upload?
    params[:upload_context].to_s == "monthly_collection"
  end

  def monthly_collection_bank_statement_upload?
    monthly_collection_upload? && params[:document_kind].to_s == "bank_statement"
  end

  def upload_period
    parse_period_param(params[:period]) || Date.current.beginning_of_month
  end

  def enqueue_bank_statement_import!
    return unless @folder.client
    return unless @document.file.attached?
    return if selected_statement_institution.blank?

    import = current_user.account.bank_statement_imports.create(
      client: @folder.client,
      institution: selected_statement_institution,
      metadata: { source_document_id: @document.id }
    )
    return unless import.persisted?

    import.file.attach(@document.file.blob)
    ProcessBankStatementImportJob.perform_later(import.id)
    record_audit_event(
      event_type: "bank_statement_import.enqueued",
      subject: import,
      metadata: { source_document_id: @document.id, institution_id: import.institution_id }
    )
  end

  def selected_statement_institution
    return @selected_statement_institution if defined?(@selected_statement_institution)

    @selected_statement_institution = current_user.account.institutions.find_by(id: params[:institution_id])
  end

end

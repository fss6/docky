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
    @available_tags = Document.pluck(:tags)
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

    @documents = Document.includes(:user, :folder).with_attached_file.order(created_at: :desc)

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
    @documents = Document.includes(:user, :folder).with_attached_file.order(created_at: :desc)

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

  def move
    destination_folder = Folder.find(params.expect(:folder_id))
    @document.update!(folder: destination_folder)
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

    redirect_back fallback_location: document_path(@document), notice: "Tag atualizada com sucesso."
  end

  def remove_tag
    tag_to_remove = params[:tag].to_s
    tags = @document.tags.reject { |tag| tag.casecmp(tag_to_remove).zero? }
    @document.update!(tags: tags)

    redirect_back fallback_location: document_path(@document), notice: "Tag removida com sucesso."
  end

  private

  def authorize_policy
    record = @document || Document
    authorize record
  end

  def set_folder
    @folder = Folder.find(params.expect(:folder_id))
  end

  def set_document
    @document = Document.includes(:account, :user, :folder, :embedding_records).with_attached_file.find(params.expect(:id))
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
    params[:upload_context].to_s == "folder" ? folder_path(@folder) : folder_documents_path(@folder)
  end
end

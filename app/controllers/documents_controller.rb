class DocumentsController < ApplicationController
  include FoldersHelper

  before_action :set_document, only: %i[show destroy move add_tag replace_tag remove_tag]
  before_action :authorize_policy

  def show
  end

  def tags_search
    @available_tags = Document.all.pluck(:tags)
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

    @documents = Document.all.includes(:user, :folder).with_attached_file.order(created_at: :desc)

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
    @documents = Document.all.includes(:user, :folder).with_attached_file.order(created_at: :desc)

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

  def destroy
    folder = @document.folder
    Wiki::CleanupDocumentService.new(account: @document.account, document_id: @document.id).call
    @document.destroy!

    respond_to do |format|
      format.html { redirect_to folder_destination_path(folder), notice: "Documento excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def move
    destination_folder = Folder.find(params.expect(:folder_id))
    source_folder_id = @document.folder_id
    @document.update!(folder: destination_folder)
    record_audit_event(
      event_type: "document.moved",
      subject: @document,
      metadata: { from_folder_id: source_folder_id, to_folder_id: destination_folder.id }
    )
    respond_to do |format|
      format.html do
        redirect_back fallback_location: folder_destination_path(destination_folder),
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

  def set_document
    @document = Document
      .includes(:account, :user, :folder, :embedding_records)
      .with_attached_file
      .find(params.expect(:id))
  end
end

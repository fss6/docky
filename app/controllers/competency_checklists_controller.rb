class CompetencyChecklistsController < ApplicationController
  before_action :set_folder
  before_action :require_folder_client!
  before_action :set_period
  before_action :set_checklist
  before_action :authorize_checklist
  before_action :set_item, only: %i[mark_validated mark_pending remove_item attach_document detach_document]

  def show
    @items = @checklist.items.includes(:validated_by_user).order(:id)
    @available_documents = documents_for_period
  end

  def refresh_receipts
    redirect_to redirect_path_with_fallback(checklist_path), alert: "A associação agora é manual. Selecione o documento em cada item."
  end

  def create_template_item
    item = @checklist.items.new(
      name_snapshot: params[:name].to_s.strip,
      match_terms: parse_match_terms(params[:match_terms]),
      state: :pending
    )

    if item.save
      redirect_to redirect_path_with_fallback(checklist_path), notice: "Item adicionado com sucesso."
    else
      redirect_to redirect_path_with_fallback(checklist_path), alert: item.errors.full_messages.to_sentence
    end
  end

  def attach_document
    document = documents_for_period.find(params.expect(:document_id))
    attrs = {
      last_document: document,
      received_at: Time.current,
      state: :validated,
      validated_by_user: current_user,
      validated_at: Time.current
    }
    if @item.update(attrs)
      redirect_to redirect_path_with_fallback(checklist_path), notice: "Documento vinculado ao item."
    else
      redirect_to redirect_path_with_fallback(checklist_path), alert: @item.errors.full_messages.to_sentence
    end
  end

  def detach_document
    @item.update!(
      last_document: nil,
      received_at: nil,
      state: :pending,
      validated_by_user: nil,
      validated_at: nil
    )
    redirect_to redirect_path_with_fallback(checklist_path), notice: "Documento desvinculado do item."
  end

  def mark_validated
    @item.mark_validated!(user: current_user)
    redirect_to redirect_path_with_fallback(checklist_path), notice: "Item validado."
  end

  def mark_pending
    @item.mark_pending!
    redirect_to redirect_path_with_fallback(checklist_path), notice: "Item reaberto como pendente."
  end

  def remove_item
    @item.destroy!
    redirect_to redirect_path_with_fallback(checklist_path), notice: "Item removido com sucesso."
  end

  private

  def set_folder
    @folder = Folder.for_nav_client(current_client).includes(:client).find(params.expect(:folder_id))
  end

  def require_folder_client!
    return if @folder.client.present?

    skip_authorization
    redirect_to @folder, alert: "Esta pasta não está vinculada a um cliente."
  end

  def set_period
    @period = parse_period(params[:period]) || Date.current.beginning_of_month
  end

  def set_checklist
    @checklist = Checklist::BuildForCompetency.new(
      account: current_user.account,
      client: @folder.client,
      period: @period
    ).call
  end

  def set_item
    @item = @checklist.items.find(params.expect(:item_id))
  end

  def authorize_checklist
    authorize @checklist, policy_class: CompetencyChecklistPolicy
  end

  def checklist_path
    folder_competency_checklist_path(@folder, period: @period.strftime("%Y-%m"))
  end

  def documents_for_period
    @documents_for_period ||= current_user.account.documents
      .where(folder_id: @folder.id)
      .with_attached_file
      .order(created_at: :desc)
  end

  def parse_period(raw)
    parse_period_param(raw)
  end

  def parse_match_terms(raw_terms)
    raw_terms.to_s.split(",").map { |term| term.strip }.reject(&:blank?).uniq
  end

  def redirect_path_with_fallback(fallback_path)
    return_to = params[:return_to].to_s
    return fallback_path unless return_to.start_with?("/monthly-collections")

    return_to
  end
end

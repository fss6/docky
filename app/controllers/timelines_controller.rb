class TimelinesController < ApplicationController
  before_action :authorize_policy
  before_action :require_current_client!
  before_action :set_period_from_params!
  before_action :set_collection_folder
  before_action :set_checklist

  def show
    @documents = if @collection_folder
      current_user.account.documents
        .where(folder: @collection_folder)
        .with_attached_file
        .order(created_at: :desc)
    else
      current_user.account.documents.none
    end

    @pending_items = if @checklist
      @checklist.items
        .pending
        .where(last_document_id: nil)
        .order(:id)
    else
      CompetencyChecklistItem.none
    end

    @timeline_days = build_timeline_days(@documents, @pending_items)
    @kpis = build_kpis(@checklist&.items || [], @pending_items)
  end

  private

  def authorize_policy
    authorize Folder, :index?
  end

  def set_period_from_params!
    raw_period = params[:id].presence || params[:period].presence
    parsed_period = parse_period(raw_period)
    if raw_period.present? && parsed_period.nil?
      redirect_to timeline_path, alert: "Competencia invalida."
      return
    end

    @period = parsed_period || Date.current.beginning_of_month
    @period_param = @period.strftime("%Y-%m")
  end

  def set_collection_folder
    @collection_folder = Folder.find_by(
      account: current_user.account,
      client: current_client,
      name: @period_param
    )
  end

  def set_checklist
    @checklist = CompetencyChecklist.find_by(
      account: current_user.account,
      client: current_client,
      period: @period
    )
  end

  def parse_period(raw_period)
    parse_period_param(raw_period)
  end

  def build_timeline_days(documents, pending_items)
    received_days = documents
      .group_by { |document| document.created_at.in_time_zone.to_date }
      .sort_by { |(date, _)| -date.jd }
      .map do |date, day_documents|
        {
          date: date,
          label: l(date, format: :long),
          kind: :received,
          events: day_documents.map { |document| build_received_event(document) }
        }
      end

    return received_days if pending_items.blank?

    received_days + [{
      date: nil,
      label: "Faltas do mês",
      kind: :missing,
      events: pending_items.map { |item| build_missing_event(item) }
    }]
  end

  def build_received_event(document)
    {
      kind: :received_document,
      title: helpers.document_file_label(document),
      subtitle: "Enviado às #{document.created_at.in_time_zone.strftime("%H:%M")}",
      badge: "Recebido",
      amount: nil,
      cta_label: "Abrir documento",
      cta_path: document_path(document)
    }
  end

  def build_missing_event(item)
    {
      kind: :missing_item,
      title: item.name_snapshot,
      subtitle: "Item do checklist sem documento vinculado",
      badge: "Pendente",
      amount: nil,
      cta_label: "Cobrar cliente",
      cta_path: monthly_collection_path(@period_param)
    }
  end

  def build_kpis(items, pending_items)
    total_count = items.size
    received_count = items.count(&:received?)
    validated_count = items.count(&:validated?)
    pending_count = pending_items.size

    progress_percent = if total_count.positive?
      ((validated_count.to_f / total_count) * 100).round
    else
      0
    end

    {
      total_count: total_count,
      received_count: received_count,
      validated_count: validated_count,
      pending_count: pending_count,
      progress_percent: progress_percent
    }
  end
end

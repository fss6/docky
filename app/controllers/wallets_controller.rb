class WalletsController < ApplicationController
  before_action :authorize_policy

  STATUS_ORDER = {
    "critical" => 0,
    "awaiting" => 1,
    "in_review" => 2,
    "on_track" => 3
  }.freeze

  def index
    @period = parse_period(params[:period]) || Date.current.beginning_of_month
    @period_param = @period.strftime("%Y-%m")
    @search_query = params[:q].to_s.strip
    @selected_status = params[:status].to_s
    @only_pending = ActiveModel::Type::Boolean.new.cast(params[:only_pending])

    @rows = build_rows
    @rows = filter_rows(@rows)
    @rows = sort_rows(@rows)
    @kpis = build_kpis(@rows)
  end

  private

  def authorize_policy
    authorize Client, :index?
  end

  def parse_period(raw_period)
    parse_period_param(raw_period)
  end

  def build_rows
    clients = current_user.account.clients.order(:name)
    clients = clients.where("clients.name ILIKE ?", "%#{@search_query}%") if @search_query.present?

    client_ids = clients.pluck(:id)
    return [] if client_ids.empty?

    checklists = CompetencyChecklist
      .where(account: current_user.account, period: @period, client_id: client_ids)
      .includes(:client, items: :last_document)

    checklists_by_client_id = checklists.index_by(&:client_id)
    last_document_by_client_id = last_documents_by_client(client_ids: client_ids)
    critical_cutoff = Time.zone.now - 5.days

    clients.map do |client|
      checklist = checklists_by_client_id[client.id]
      items = checklist&.items.to_a || []
      total_count = items.size
      pending_count = items.count(&:pending?)
      received_count = items.count(&:received?)
      validated_count = items.count(&:validated?)
      progress_percent = total_count.positive? ? ((validated_count.to_f / total_count) * 100).round : 0
      last_document_at = last_document_by_client_id[client.id]
      status_key = status_for(
        total_count: total_count,
        pending_count: pending_count,
        received_count: received_count,
        validated_count: validated_count,
        last_document_at: last_document_at,
        critical_cutoff: critical_cutoff
      )

      {
        client: client,
        status_key: status_key,
        status_label: status_label_for(status_key),
        total_count: total_count,
        pending_count: pending_count,
        received_count: received_count,
        validated_count: validated_count,
        progress_percent: progress_percent,
        last_document_at: last_document_at
      }
    end
  end

  def last_documents_by_client(client_ids:)
    current_user.account.documents
      .joins(:folder)
      .where(folders: { client_id: client_ids, name: @period_param })
      .group("folders.client_id")
      .maximum("documents.created_at")
  end

  def status_for(total_count:, pending_count:, received_count:, validated_count:, last_document_at:, critical_cutoff:)
    return "critical" if pending_count.positive? && (last_document_at.nil? || last_document_at < critical_cutoff)
    return "on_track" if total_count.positive? && validated_count == total_count
    return "in_review" if pending_count.positive? && received_count.positive?

    "awaiting"
  end

  def status_label_for(status_key)
    {
      "critical" => "Crítico",
      "awaiting" => "Aguardando envio",
      "in_review" => "Em validação",
      "on_track" => "Em dia"
    }.fetch(status_key, "Aguardando envio")
  end

  def filter_rows(rows)
    rows = rows.select { |row| row[:status_key] == @selected_status } if STATUS_ORDER.key?(@selected_status)
    rows = rows.select { |row| row[:pending_count].positive? } if @only_pending
    rows
  end

  def sort_rows(rows)
    rows.sort_by do |row|
      [
        STATUS_ORDER.fetch(row[:status_key], 99),
        -row[:pending_count],
        row[:last_document_at] || Time.at(0),
        row[:client].name.to_s.downcase
      ]
    end
  end

  def build_kpis(rows)
    total_clients = rows.size
    critical_clients = rows.count { |row| row[:status_key] == "critical" }
    no_recent_documents = rows.count { |row| row[:last_document_at].nil? }
    average_progress = if total_clients.positive?
      (rows.sum { |row| row[:progress_percent] } / total_clients.to_f).round
    else
      0
    end

    {
      total_clients: total_clients,
      critical_clients: critical_clients,
      no_recent_documents: no_recent_documents,
      average_progress: average_progress
    }
  end
end

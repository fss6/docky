# frozen_string_literal: true

class AuditsController < ApplicationController
  before_action :authorize_policy

  def index
    @actor_options = current_user.account.users.order(:name).pluck(:name, :id)

    logs_scope = unified_logs_scope
    @pagy, @logs = pagy(logs_scope, limit: 10)
    preload_log_context!
    @presented_logs = @logs.map { |log| build_log_presenter(log) }
  end

  private

  def authorize_policy
    authorize :audit
  end

  def unified_logs_scope
    audits_sql = filtered_audits_scope.select(
      "audits.id AS row_id",
      "'audit' AS source",
      "audits.created_at",
      "audits.user_id",
      "users.name AS actor_name",
      "audits.action AS verb",
      "audits.auditable_type AS item_type",
      "audits.auditable_id AS item_id",
      "audits.audited_changes AS payload"
    ).to_sql

    events_sql = filtered_audit_events_scope.select(
      "audit_events.id AS row_id",
      "'event' AS source",
      "audit_events.created_at",
      "audit_events.user_id",
      "users.name AS actor_name",
      "audit_events.event_type AS verb",
      "audit_events.subject_type AS item_type",
      "audit_events.subject_id AS item_id",
      "audit_events.metadata::text AS payload"
    ).to_sql

    union_parts = []
    union_parts << audits_sql unless params[:source] == "event"
    union_parts << events_sql unless params[:source] == "audit"
    union_sql = "(#{union_parts.join(' UNION ALL ')}) AS audit_logs"

    scope = Audit.unscoped
      .from(union_sql)
      .select("audit_logs.*")

    if params[:q].present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.where(
        "audit_logs.verb ILIKE :q OR audit_logs.item_type ILIKE :q OR audit_logs.actor_name ILIKE :q OR audit_logs.payload ILIKE :q",
        q: like
      )
    end

    scope.order("audit_logs.created_at DESC, audit_logs.row_id DESC")
  end

  def filtered_audits_scope
    scope = Audit
      .where(account_id: current_user.account_id)
      .joins("LEFT JOIN users ON users.id = audits.user_id")

    scope = scope.where(user_id: params[:actor_id]) if params[:actor_id].present?
    scope = scope.where(action: params[:verb]) if params[:verb].present?
    scope = scope.where(auditable_type: params[:item_type]) if params[:item_type].present?
    from_date = parse_date(params[:from])
    to_date = parse_date(params[:to])
    scope = scope.where("audits.created_at >= ?", from_date.beginning_of_day) if from_date
    scope = scope.where("audits.created_at <= ?", to_date.end_of_day) if to_date
    scope
  end

  def filtered_audit_events_scope
    scope = AuditEvent
      .where(account_id: current_user.account_id)
      .joins("LEFT JOIN users ON users.id = audit_events.user_id")

    scope = scope.where(user_id: params[:actor_id]) if params[:actor_id].present?
    scope = scope.where(event_type: params[:verb]) if params[:verb].present?
    scope = scope.where(subject_type: params[:item_type]) if params[:item_type].present?
    from_date = parse_date(params[:from])
    to_date = parse_date(params[:to])
    scope = scope.where("audit_events.created_at >= ?", from_date.beginning_of_day) if from_date
    scope = scope.where("audit_events.created_at <= ?", to_date.end_of_day) if to_date
    scope
  end

  def parse_date(raw_date)
    return nil if raw_date.blank?

    Date.parse(raw_date.to_s)
  rescue ArgumentError
    nil
  end

  def preload_log_context!
    event_ids = @logs.select { |log| log.source == "event" }.map(&:row_id)
    audit_ids = @logs.select { |log| log.source == "audit" }.map(&:row_id)

    @audit_events_by_id = AuditEvent
      .where(id: event_ids, account_id: current_user.account_id)
      .index_by(&:id)
    @audits_by_id = Audit
      .where(id: audit_ids, account_id: current_user.account_id)
      .index_by(&:id)
    @subject_labels = AuditLog::SubjectLabelResolver.call(
      @logs,
      account_id: current_user.account_id
    )
  end

  def build_log_presenter(log)
    AuditLog::Presenter.new(
      log,
      audit_events_by_id: @audit_events_by_id,
      audits_by_id: @audits_by_id,
      subject_labels: @subject_labels
    )
  end
end

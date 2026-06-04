# frozen_string_literal: true

module Platform
  class CollectionDispatchMonitor
    KPI_WINDOW = 7.days

    FilterParams = Struct.new(
      :status,
      :channel,
      :account_id,
      :skip_reason,
      :from,
      :to,
      :q,
      keyword_init: true
    )

    Result = Struct.new(:scope, :kpis, :stale_scheduled_count, :account_options, keyword_init: true)

    def self.call(params: {})
      new(params: params).call
    end

    def initialize(params: {})
      @params = params
    end

    def call
      Result.new(
        scope: filtered_scope,
        kpis: kpi_counts,
        stale_scheduled_count: stale_scheduled_count,
        account_options: account_options
      )
    end

    def self.filter_params_from(params)
      FilterParams.new(
        status: params[:status].presence,
        channel: params[:channel].presence,
        account_id: params[:account_id].presence,
        skip_reason: params[:skip_reason].presence,
        from: params[:from].presence,
        to: params[:to].presence,
        q: params[:q].to_s.strip.presence
      )
    end

    private

    def base_scope
      CollectionDispatch
        .unscoped
        .includes(:account, :client, :collection_step, :period, :delivery_events)
        .order(created_at: :desc, id: :desc)
    end

    def filtered_scope
      scope = base_scope
      filters = self.class.filter_params_from(@params)

      scope = scope.where(status: filters.status) if filters.status.present?
      scope = scope.where(channel: filters.channel) if filters.channel.present?
      scope = scope.where(account_id: filters.account_id) if filters.account_id.present?
      scope = scope.where(skip_reason: filters.skip_reason) if filters.skip_reason.present?

      from_date = parse_date(filters.from)
      to_date = parse_date(filters.to)
      scope = scope.where(created_at: from_date.beginning_of_day..) if from_date
      scope = scope.where(created_at: ..to_date.end_of_day) if to_date

      if filters.q.present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(filters.q)}%"
        scope = scope.joins(:client).where(
          "clients.name ILIKE :q OR clients.email ILIKE :q",
          q: like
        )
      end

      scope
    end

    def kpi_counts
      recent = CollectionDispatch.unscoped.recent(since: KPI_WINDOW.ago)
      {
        scheduled: recent.status_scheduled.count,
        sent: recent.status_sent.count,
        failed: recent.status_failed.count,
        skipped: recent.status_skipped.count
      }
    end

    def stale_scheduled_count
      CollectionDispatch.unscoped.stale_scheduled.count
    end

    def account_options
      Account.order(:name).pluck(:name, :id)
    end

    def parse_date(raw)
      return nil if raw.blank?

      Date.parse(raw.to_s)
    rescue ArgumentError
      nil
    end
  end
end

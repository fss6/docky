# frozen_string_literal: true

module Collection
  class PanelPresenter
    Row = Struct.new(
      :client,
      :period_record,
      :pending_items,
      :deadline_date,
      :days_offset,
      :badge,
      :next_action_label,
      :period_label,
      keyword_init: true
    )

    VALID_STATUSES = %w[late due soon].freeze

    def self.call(account:, status: nil, period_filter: nil, search_query: nil)
      new(account: account, status: status, period_filter: period_filter, search_query: search_query).call
    end

    def initialize(account:, status: nil, period_filter: nil, search_query: nil)
      @account = account
      @status = status.to_s.presence
      @status = nil unless VALID_STATUSES.include?(@status)
      @period_filter = period_filter&.to_date&.beginning_of_month
      @search_query = search_query.to_s.strip
    end

    def call
      all_rows = build_all_rows
      {
        rows: apply_filters(all_rows),
        kpis: build_kpis(all_rows)
      }
    end

    private

    def build_all_rows
      scope = Period.open_periods
        .where(account: @account)
        .joins(:client)
        .merge(Client.kept.where(status: :active))
        .includes(:client, items: :last_document)
        .order(period: :asc)

      scope.filter_map do |period_record|
        client = period_record.client
        pending = period_record.items.select(&:awaiting_receipt?)
        next if pending.empty?

        deadline = Deadline.for(client: client, period: period_record.period)
        days_offset = (Date.current - deadline).to_i

        Row.new(
          client: client,
          period_record: period_record,
          pending_items: pending,
          deadline_date: deadline,
          days_offset: days_offset,
          badge: badge_for(days_offset),
          next_action_label: next_action(days_offset: days_offset, step: step_for(days_offset)),
          period_label: PeriodFormatting.display_label(period_record.period)
        )
      end.sort_by { |row| [-row.days_offset, row.client.name.downcase, row.period_record.period] }
    end

    def apply_filters(rows)
      filtered = rows
      if @period_filter
        filtered = filtered.select { |row| row.period_record.period == @period_filter }
      end
      if @search_query.present?
        like = @search_query.downcase
        filtered = filtered.select { |row| row.client.name.downcase.include?(like) }
      end
      apply_status_filter(filtered)
    end

    def apply_status_filter(rows)
      case @status
      when "late"
        rows.select { |r| r.days_offset.positive? }
      when "due"
        rows.select { |r| r.days_offset.zero? }
      when "soon"
        rows.select { |r| r.days_offset.negative? }
      else
        rows
      end
    end

    def badge_for(days_offset)
      if days_offset.positive?
        { key: :late, label: "#{days_offset}d atraso" }
      elsif days_offset.zero?
        { key: :due, label: "vence hoje" }
      else
        { key: :soon, label: "vence em #{days_offset.abs}d" }
      end
    end

    def step_for(days_offset)
      @account.collection_steps.find_by(offset_days: days_offset)
    end

    def next_action(days_offset:, step:)
      return "Nenhum degrau para hoje" unless step

      channels = step.channels_enabled
      return "Aviso interno ao gestor" if step.kind_internal_alert?

      labels = []
      labels << "e-mail" if channels.include?(:email)
      labels << "WhatsApp" if channels.include?(:whatsapp)
      return "Aguardando próximo degrau" if labels.empty?

      "Próxima: #{labels.join(' + ')} (degrau: #{step.name})"
    end

    def build_kpis(all_rows)
      clients_with_pending = all_rows.map { |r| r.client.id }.uniq
      active_client_count = @account.clients.kept.where(status: :active).count

      {
        late: all_rows.count { |r| r.days_offset.positive? },
        due_today: all_rows.count { |r| r.days_offset.zero? },
        on_track: [active_client_count - clients_with_pending.size, 0].max,
        messages_month: CollectionDispatch.status_sent
          .sent_in_month(Date.current)
          .where(account: @account)
          .count
      }
    end
  end
end

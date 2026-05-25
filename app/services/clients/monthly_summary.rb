# frozen_string_literal: true

module Clients
  class MonthlySummary
    def initialize(client:, checklist:, period:)
      @client = client
      @checklist = checklist
      @period = period.to_date.beginning_of_month
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: 30.seconds) { build }
    end

    private

    def cache_key
      "client_summary/#{@client.account_id}/#{@client.id}/#{@period}"
    end

    def build
      items = @checklist&.items&.to_a || []
      total = items.size
      linked = items.count { |i| i.last_document_id.present? }
      pending = items.count { |i| i.last_document_id.blank? }

      last_upload = Document.where(client_id: @client.id, collection_period: @period).maximum(:created_at)

      {
        pending_count: pending,
        total_count: total,
        linked_count: linked,
        progress_label: total.positive? ? "#{linked} de #{total} itens" : "0 itens",
        status_badge: status_badge(pending),
        deadline: deadline_payload,
        last_upload_label: last_upload ? ActionController::Base.helpers.time_ago_in_words(last_upload) : "—"
      }
    end

    def status_badge(pending_count)
      if pending_count.positive?
        { tone: :warning, label: "#{pending_count} pendência#{'s' if pending_count != 1}" }
      else
        { tone: :success, label: "Em dia" }
      end
    end

    def deadline_payload
      day = @client.monthly_deadline_day.clamp(1, 28)
      deadline = @period.change(day: day)
      deadline = deadline.end_of_month if day > deadline.end_of_month.day

      days_left = (deadline.to_date - Date.current).to_i
      {
        date_label: I18n.l(deadline.to_date, format: :short),
        days_left: days_left,
        label: "Fecha em #{I18n.l(deadline.to_date, format: :short)} · #{days_left.positive? ? "faltam #{days_left} dias" : (days_left.zero? ? "vence hoje" : "prazo encerrado")}"
      }
    end
  end
end

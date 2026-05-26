# frozen_string_literal: true

module Clients
  class MonthlySummary
    def initialize(client:, checklist:, period:, period_record: nil)
      @client = client
      @checklist = checklist
      @period_record = period_record || checklist
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
      linked = items.count(&:complete_for_collection?)
      pending = items.count(&:awaiting_receipt?)
      phase = period_phase

      last_upload = if @period_record&.id
                      Document.where(client_id: @client.id, period_id: @period_record.id).maximum(:created_at)
                    else
                      Document.where(client_id: @client.id, collection_period: @period).maximum(:created_at)
                    end

      {
        pending_count: pending,
        total_count: total,
        linked_count: linked,
        progress_label: total.positive? ? "#{linked} de #{total} itens" : "0 itens",
        period_phase: phase,
        status_badge: status_badge(pending, phase),
        deadline: deadline_payload(phase),
        last_upload_label: last_upload ? ActionController::Base.helpers.time_ago_in_words(last_upload) : "—"
      }
    end

    def period_phase
      current = Date.current.beginning_of_month
      return :future if @period > current
      return :past if @period < current

      :current
    end

    def status_badge(pending_count, phase)
      if @period_record&.closed?
        return { tone: :neutral, label: "Competência encerrada" }
      end

      if phase == :past
        if pending_count.positive?
          {
            tone: :warning,
            label: "#{pending_count} pendência#{"s" if pending_count != 1} em aberto"
          }
        else
          { tone: :success, label: "Mês concluído" }
        end
      elsif pending_count.positive?
        { tone: :warning, label: "#{pending_count} pendência#{"s" if pending_count != 1}" }
      else
        { tone: :success, label: "Em dia" }
      end
    end

    def deadline_payload(phase)
      day = @client.monthly_deadline_day.clamp(1, 28)
      deadline = @period.change(day: day)
      deadline = deadline.end_of_month if day > deadline.end_of_month.day
      deadline_date = deadline.to_date
      days_left = (deadline_date - Date.current).to_i
      date_label = I18n.l(deadline_date, format: :short)
      month_name = I18n.l(@period, format: "%B").downcase

      label = if phase == :past
                "Prazo de #{month_name} encerrado em #{date_label}"
              elsif phase == :future
                "Prazo previsto para #{date_label}"
              elsif days_left.positive?
                "Fecha em #{date_label} · faltam #{days_left} dias"
              elsif days_left.zero?
                "Fecha em #{date_label} · vence hoje"
              else
                "Prazo de #{month_name} encerrado em #{date_label}"
              end

      {
        date_label: date_label,
        days_left: days_left,
        label: label
      }
    end
  end
end

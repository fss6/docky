# frozen_string_literal: true

module Clients
  module RequiresPeriodRecord
    extend ActiveSupport::Concern

    private

    def load_monthly_collection_readonly
      @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
      @monthly = Clients::EnsureMonthlyCollection.call(
        client: @client,
        period: @period,
        create_if_missing: false
      )
      redirect_to_client_without_period! if @monthly.period_record.blank?
    end

    def redirect_to_client_without_period!
      aba = params[:aba].presence || default_period_redirect_aba
      redirect_to client_path(@client, aba: aba, period: @period.strftime("%Y-%m")),
                  alert: "Abra a competência antes de continuar.",
                  status: :see_other
    end

    def default_period_redirect_aba
      "documentos"
    end
  end
end

# frozen_string_literal: true

module Clients
  class PeriodsController < ApplicationController
    before_action :set_client
    before_action :set_period_record
    before_action :authorize_period

    def close
      if Periods::Close.call(period: @period_record, user: current_user, ip: request.remote_ip)
        redirect_to client_path(@client, aba: params[:aba].presence || "documentos", period: @period_param),
                    notice: "Competência encerrada com sucesso.",
                    status: :see_other
      else
        redirect_to client_path(@client, aba: params[:aba].presence || "documentos", period: @period_param),
                    alert: "Esta competência já está encerrada.",
                    status: :see_other
      end
    end

    def reopen
      if Periods::Reopen.call(period: @period_record, user: current_user, ip: request.remote_ip)
        redirect_to client_path(@client, aba: params[:aba].presence || "documentos", period: @period_param),
                    notice: "Competência reaberta com sucesso.",
                    status: :see_other
      else
        redirect_to client_path(@client, aba: params[:aba].presence || "documentos", period: @period_param),
                    alert: "Esta competência já está aberta.",
                    status: :see_other
      end
    end

    private

    def set_client
      @client = Client.find(params.expect(:id))
    end

    def set_period_record
      @period_date = parse_period_param(params[:period])
      return redirect_missing_period! if @period_date.blank?

      @period_param = @period_date.strftime("%Y-%m")
      @period_record = Period.find_by(account: current_user.account, client: @client, period: @period_date)
      return redirect_missing_period! if @period_record.blank?
    end

    def authorize_period
      action = action_name == "reopen" ? :reopen? : :close?
      authorize @period_record, action
    end

    def redirect_missing_period!
      redirect_to client_path(@client), alert: "Competência inválida.", status: :see_other
    end
  end
end

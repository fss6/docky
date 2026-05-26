# frozen_string_literal: true

module Clients
  class ChecklistItemsController < ApplicationController
    before_action :set_client
    before_action :authorize_client

    def index
      @template_items = @client.client_checklist_items.active_only
      @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
      @checklist = Checklist::BuildForCompetency.new(
        account: current_user.account,
        client: @client,
        period: @period
      ).call
    end

    def create
      item = @client.client_checklist_items.new(template_item_params)
      item.account = current_user.account
      if item.save
        redirect_to client_checklist_items_path(@client), notice: "Item adicionado ao template."
      else
        @template_items = @client.client_checklist_items.active_only
        render :index, status: :unprocessable_entity
      end
    end

    def sync_to_month
      @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
      checklist = Checklist::BuildForCompetency.new(
        account: current_user.account,
        client: @client,
        period: @period
      ).call
      Clients::SyncTemplateToMonth.call(client: @client, checklist: checklist)
      Clients::InvalidateSummaryCache.call(client: @client, period: @period)
      load_client_checklist_context

      respond_to do |format|
        format.turbo_stream { render :sync_to_month }
        format.html do
          redirect_to client_path(@client, aba: "checklist", period: @period_param),
                      notice: "Checklist montado para o mês.",
                      status: :see_other
        end
      end
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def authorize_client
      authorize @client, :update?
    end

    def load_client_checklist_context
      @monthly = Clients::EnsureMonthlyCollection.call(client: @client, period: @period)
      @checklist = @monthly.checklist
      @checklist.items.reset
      @checklist_items = @checklist.items.includes(:last_document, :validated_by_user).order(:id)
      @summary = Clients::MonthlySummary.new(client: @client, checklist: @checklist, period: @period).call
      @period_param = @period.strftime("%Y-%m")
      @template_items_count = @client.client_checklist_items.active_only.count
      @active_tab = "checklist"
      flash.now[:notice] = "Checklist montado para o mês."
    end

    def template_item_params
      params.expect(client_checklist_item: [:name, :position, :active])
    end
  end
end

# frozen_string_literal: true

module Clients
  class CompetencyChecklistItemsController < ApplicationController
    before_action :set_client
    before_action :set_period
    before_action :set_monthly
    before_action :set_item

    def mark_validated
      authorize @client, :show?

      if MarkChecklistItemValidated.call(item: @item, user: current_user, ip: request.remote_ip)
        flash.now[:notice] = "Item conferido."
        load_checklist_context
        render_checklist_update
      else
        flash.now[:alert] = "Não foi possível marcar o item."
        load_checklist_context
        render_checklist_update(status: :unprocessable_entity)
      end
    end

    def mark_pending
      authorize @client, :show?

      if MarkChecklistItemPending.call(item: @item, user: current_user, ip: request.remote_ip)
        flash.now[:notice] = "Item reaberto como pendente."
        load_checklist_context
        render_checklist_update
      else
        flash.now[:alert] = "Desvincule o documento antes de reabrir este item."
        load_checklist_context
        render_checklist_update(status: :unprocessable_entity)
      end
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def set_period
      @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
    end

    def set_monthly
      @monthly = EnsureMonthlyCollection.call(client: @client, period: @period)
    end

    def set_item
      @item = @monthly.checklist.items.find(params.expect(:id))
    end

    def load_checklist_context
      @checklist = @monthly.checklist
      @checklist.items.reset
      @checklist_items = @checklist.items.includes(:last_document, :validated_by_user).order(:id)
      @summary = MonthlySummary.new(client: @client, checklist: @checklist, period: @period).call
      @period_param = @period.strftime("%Y-%m")
    end

    def render_checklist_update(status: :ok)
      respond_to do |format|
        format.turbo_stream { render :update_checklist, status: status }
        format.html do
          redirect_to client_path(@client, aba: "checklist", period: @period_param),
                      flash: flash.to_hash,
                      status: :see_other
        end
      end
    end
  end
end

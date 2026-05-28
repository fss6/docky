# frozen_string_literal: true

module Clients
  class OnboardingChecklistItemsController < BaseController
    before_action :set_client
    before_action :set_checklist
    before_action :set_item, only: %i[update destroy mark_received mark_pending]

    def index
      authorize @client, :manage_onboarding_checklist?
      @items = @checklist.items.ordered
    end

    def create
      authorize @client, :manage_onboarding_checklist?
      @item = @checklist.items.build(item_params)
      @item.position = (@checklist.items.maximum(:position) || -1) + 1

      if @item.save
        redirect_to @client, notice: "Item adicionado ao onboarding."
      else
        @items = @checklist.items.ordered
        render :index, status: :unprocessable_entity
      end
    end

    def update
      authorize @client, :manage_onboarding_checklist?

      if @item.update(item_params)
        redirect_to @client, notice: "Item atualizado."
      else
        @items = @checklist.items.ordered
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @client, :manage_onboarding_checklist?
      @item.destroy!
      redirect_to @client, notice: "Item removido."
    end

    def mark_received
      authorize @client, :manage_onboarding_checklist?
      Onboarding::MarkItemReceived.call(item: @item, user: current_user)
      redirect_to @client, notice: "Item marcado como recebido.", status: :see_other
    end

    def mark_pending
      authorize @client, :manage_onboarding_checklist?
      @item.mark_pending!
      redirect_to @client, notice: "Item reaberto.", status: :see_other
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def set_checklist
      @checklist = @client.onboarding_checklist
      return if @checklist

      redirect_to @client, alert: "Checklist de onboarding não encontrado.", status: :see_other
    end

    def set_item
      @item = @checklist.items.find(params.expect(:id))
    end

    def item_params
      params.expect(onboarding_checklist_item: [:name, :help_text])
    end
  end
end

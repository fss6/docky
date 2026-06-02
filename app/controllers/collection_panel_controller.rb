# frozen_string_literal: true

class CollectionPanelController < ApplicationController
  before_action :authorize_policy

  def index
    @status_filter = normalized_status_filter
    @search_query = params[:q].to_s.strip

    data = Collection::PanelPresenter.call(
      account: current_user.account,
      status: @status_filter,
      search_query: @search_query
    )
    @rows = data[:rows]
    @kpis = data[:kpis]
    load_timeline_if_selected
    @collection_enabled = current_user.account.collection_setting&.enabled?
    @email_configured = ActionMailerDelivery.enabled?
    @whatsapp_configured = Whatsapp::PlatformConfig.configured?
  end

  private

  def authorize_policy
    authorize Client, :index?
  end

  def normalized_status_filter
    status = params[:status].to_s
    return status if Collection::PanelPresenter::VALID_STATUSES.include?(status)

    nil
  end

  def load_timeline_if_selected
    @selected_row = find_selected_row || @rows.first
    return unless @selected_row

    @timeline = Collection::TimelineBuilder.call(
      client: @selected_row.client,
      period_record: @selected_row.period_record
    )
  end

  def find_selected_row
    if params[:period_id].present?
      return @rows.find { |r| r.period_record.id == params[:period_id].to_i }
    end

    if params[:client_id].present?
      client_id = params[:client_id].to_i
      return @rows.find { |r| r.client.id == client_id }
    end

    nil
  end
end

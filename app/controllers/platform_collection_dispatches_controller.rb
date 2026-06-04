# frozen_string_literal: true

class PlatformCollectionDispatchesController < ApplicationController
  before_action :authorize_platform_access
  before_action :set_dispatch, only: :show

  def index
    monitor = ActsAsTenant.without_tenant { Platform::CollectionDispatchMonitor.call(params: params) }
    @filters = Platform::CollectionDispatchMonitor.filter_params_from(params)
    @kpis = monitor.kpis
    @stale_scheduled_count = monitor.stale_scheduled_count
    @account_options = monitor.account_options
    @pagy, @dispatches = pagy(monitor.scope, limit: 50)
  end

  def show
  end

  private

  def authorize_platform_access
    authorize PlatformSetting, :show?
  end

  def set_dispatch
    @dispatch = ActsAsTenant.without_tenant do
      CollectionDispatch
        .includes(:account, :client, :collection_step, :period, :delivery_events)
        .find(params[:id])
    end
  end
end

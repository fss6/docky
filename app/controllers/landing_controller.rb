class LandingController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :find_current_tenant
  skip_after_action :verify_authorized

  layout "landing"

  def index; end

  def privacy; end
end

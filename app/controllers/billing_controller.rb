class BillingController < ApplicationController
  skip_after_action :verify_authorized

  def pending
  end
end

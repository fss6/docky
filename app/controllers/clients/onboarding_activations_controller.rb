# frozen_string_literal: true

module Clients
  class OnboardingActivationsController < BaseController
    before_action :set_client

    def create
      authorize @client, :activate_onboarding?

      Clients::ActivateFromOnboarding.call(client: @client, user: current_user, automatic: false)
      redirect_to client_path(@client, period: Date.current.strftime("%Y-%m")),
                  notice: "#{@client.name} está ativo. Competência #{I18n.l(Date.current.beginning_of_month, format: '%B/%Y')} aberta.",
                  status: :see_other
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end
  end
end

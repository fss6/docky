# frozen_string_literal: true

module Clients
  class OnboardingReopensController < ApplicationController
    before_action :set_client

    def create
      authorize @client, :reopen_onboarding?

      Clients::ReopenOnboarding.call(client: @client, user: current_user)
      redirect_to @client, notice: "Onboarding reaberto.", status: :see_other
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end
  end
end

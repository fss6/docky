# frozen_string_literal: true

module Clients
  class OnboardingStartsController < BaseController
    before_action :set_client

    def create
      authorize @client, :start_onboarding?

      onboarding_kind = params.fetch(:onboarding_kind, "new_client")
      Clients::StartOnboarding.call(
        client: @client,
        onboarding_kind: onboarding_kind,
        user: current_user
      )
      redirect_to @client, notice: "Onboarding iniciado.", status: :see_other
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end
  end
end

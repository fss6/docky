# frozen_string_literal: true

module Clients
  class OnboardingUploadInvitesController < ApplicationController
    before_action :set_client

    def create
      authorize @client, :show?

      unless @client.onboarding?
        return head :unprocessable_entity
      end

      @invite = Clients::CreateOnboardingUploadInvite.call(client: @client, user: current_user)

      respond_to do |format|
        format.html do
          redirect_to @client, notice: "Link de onboarding gerado."
        end
        format.json do
          render json: {
            html: render_to_string(
              partial: "clients/show/onboarding_share_modal_content",
              locals: { client: @client, invite: @invite },
              formats: [:html]
            )
          }
        end
      end
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end
  end
end

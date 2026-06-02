# frozen_string_literal: true

module Collection
  class UnsubscribesController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :find_current_tenant
    skip_before_action :set_nav_client_autocomplete_json
    skip_after_action :verify_authorized

    def show
      client = UnsubscribeToken.verify(params[:token])
      unless client
        render plain: "Link inválido ou expirado.", status: :not_found
        return
      end

      pref = ClientCollectionPreference.ensure_for!(client)
      pref.update!(email_opted_out_at: Time.current)

      render :show, layout: "public_upload"
    end
  end
end

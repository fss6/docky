# frozen_string_literal: true

module Clients
  class UploadInviteEmailsController < ApplicationController
    before_action :set_client
    before_action :set_invite

    def create
      authorize @client, :show?

      if @client.email.blank?
        return render json: { error: "Cadastre o e-mail do cliente para enviar o convite." }, status: :unprocessable_entity
      end

      unless @invite.active?
        return render json: { error: "Este link não está mais ativo." }, status: :unprocessable_entity
      end

      DeliverUploadInviteEmailJob.perform_later(
        upload_invite_id: @invite.id,
        user_id: current_user.id
      )

      render json: { message: "Envio em andamento para #{@client.email}." }
    end

    private

    def set_client
      @client = Client.find(params.expect(:client_id))
    end

    def set_invite
      @invite = @client.upload_invites.find(params.expect(:id))
    end
  end
end

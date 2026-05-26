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

      setting = current_user.account.setting || current_user.account.create_setting!
      upload_url = helpers.client_public_upload_url(@invite.token)
      rendered = UploadShareMessageRenderer.call(
        setting: setting,
        client: @client,
        url: upload_url,
        period: @invite.period
      )

      UploadInviteMailer.share_link(
        client: @client,
        invite: @invite,
        email_subject: rendered.email_subject,
        email_body: rendered.email_body,
        upload_url: upload_url,
        account_name: current_user.account.name
      ).deliver_later

      record_audit_event(
        event_type: "upload_invite.email_sent",
        subject: @invite,
        metadata: {
          client_id: @client.id,
          period: @invite.period.strftime("%Y-%m"),
          recipient: @client.email
        }
      )

      render json: { message: "E-mail enviado para #{@client.email}." }
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

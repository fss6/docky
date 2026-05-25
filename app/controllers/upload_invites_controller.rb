# frozen_string_literal: true

class UploadInvitesController < ApplicationController
  before_action :set_invite, only: %i[revoke]

  def create
    @client = Client.find(params.expect(:client_id))
    authorize @client, :show?

    period = parse_period_param(params[:period]) || Date.current.beginning_of_month
    @invite = Clients::CreateUploadInvite.call(
      client: @client,
      period: period,
      user: current_user
    )

    redirect_to client_path(@client, aba: "convites", period: period.strftime("%Y-%m")), notice: "Link gerado com sucesso."
  end

  def revoke
    authorize @invite.client, :show?
    @invite.revoke!
    record_audit_event(
      event_type: "upload_invite.revoked",
      subject: @invite,
      metadata: { client_id: @invite.client_id, period: @invite.period.strftime("%Y-%m") }
    )
    redirect_to client_path(@invite.client, aba: "convites", period: @invite.period.strftime("%Y-%m")), notice: "Link revogado."
  end

  private

  def set_invite
    @invite = UploadInvite.find(params.expect(:id))
  end
end

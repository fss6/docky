# frozen_string_literal: true

class UploadInvitesController < ApplicationController
  before_action :set_invite, only: %i[revoke]

  def create
    @client = Client.find(params.expect(:client_id))
    authorize @client, :show?

    if @client.archived?
      return redirect_to @client, alert: I18n.t("clients.archived.mutation_blocked"), status: :see_other
    end

    if @client.onboarding?
      return redirect_to @client, alert: "Use o link de onboarding nesta fase.", status: :see_other
    end

    @period = parse_period_param(params[:period]) || Date.current.beginning_of_month
    period_record = Period.find_by(
      account: current_user.account,
      client: @client,
      period: @period
    )
    unless period_record
      return redirect_to client_path(@client, aba: "convites", period: @period.strftime("%Y-%m")),
                         alert: "Abra a competência antes de gerar o link de upload.",
                         status: :see_other
    end

    guard = Periods::UploadGuard.call(period: period_record)
    unless guard.allowed
      return redirect_to client_path(@client, aba: "convites", period: @period.strftime("%Y-%m")),
                         alert: guard.reason,
                         status: :see_other
    end

    respond_to do |format|
      format.html do
        @invite = Clients::CreateUploadInvite.call(
          client: @client,
          period: @period,
          user: current_user
        )
        redirect_to client_path(@client, aba: "convites", period: @period.strftime("%Y-%m")),
                    notice: "Link gerado com sucesso."
      end
      format.turbo_stream do
        @invite = find_or_create_active_invite
        @upload_invites = UploadInvite.where(client: @client, period: @period).newest_first
        flash.now[:notice] = "Link gerado com sucesso."
        render :create, formats: :turbo_stream
      end
      format.json do
        @invite = find_or_create_active_invite
        @upload_invites = UploadInvite.where(client: @client, period: @period).newest_first
        render json: {
          html: render_to_string(
            partial: "clients/show/share_link_modal_content",
            locals: {
              client: @client,
              invite: @invite,
              period_param: @period.strftime("%Y-%m")
            },
            formats: [ :html ]
          ),
          invites_html: render_to_string(
            partial: "clients/show/tab_convites",
            locals: {
              client: @client,
              upload_invites: @upload_invites,
              period_param: @period.strftime("%Y-%m"),
              active_upload_invite: @invite
            },
            formats: [ :html ]
          )
        }
      end
    end
  end

  def revoke
    authorize @invite.client, :show?
    if @invite.client.archived?
      return redirect_to client_path(@invite.client, aba: "convites", period: period_param),
                         alert: I18n.t("clients.archived.mutation_blocked"),
                         status: :see_other
    end

    @invite.revoke!
    record_audit_event(
      event_type: "upload_invite.revoked",
      subject: @invite,
      metadata: { client_id: @invite.client_id, period: @invite.period.strftime("%Y-%m") }
    )
    redirect_to client_path(@invite.client, aba: "convites", period: period_param), notice: "Link revogado."
  end

  private

  def period_param
    return Date.current.strftime("%Y-%m") if @invite.period.blank?

    @invite.period.strftime("%Y-%m")
  end

  def set_invite
    @invite = UploadInvite.find(params.expect(:id))
  end

  def find_or_create_active_invite
    existing = UploadInvite.where(client: @client, period: @period).newest_first.find(&:active?)
    return existing if existing

    Clients::CreateUploadInvite.call(
      client: @client,
      period: @period,
      user: current_user
    )
  end
end

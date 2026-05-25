# frozen_string_literal: true

module Clients
  class CreateUploadInvite
    def self.call(client:, period:, user:, account: ActsAsTenant.current_tenant)
      new(client: client, period: period, user: user, account: account).call
    end

    def initialize(client:, period:, user:, account:)
      @client = client
      @period = period.to_date.beginning_of_month
      @user = user
      @account = account
    end

    def call
      UploadInvite.transaction do
        UploadInvite.where(client: @client, period: @period, revoked_at: nil).find_each(&:revoke!)

        invite = UploadInvite.create!(
          account: @account,
          client: @client,
          period: @period,
          created_by_user: @user,
          token: UploadInvite.generate_token
        )

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "upload_invite.created",
          subject: invite,
          metadata: { client_id: @client.id, period: @period.strftime("%Y-%m") }
        )

        invite
      end
    end
  end
end

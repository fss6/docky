# frozen_string_literal: true

module Clients
  class CreateOnboardingUploadInvite
    def self.call(client:, user:, account: nil)
      new(client: client, user: user, account: account).call
    end

    def initialize(client:, user:, account:)
      @client = client
      @user = user
      @account = account || client.account
    end

    def call
      UploadInvite.transaction do
        UploadInvite.purpose_onboarding.where(client: @client, revoked_at: nil).find_each(&:revoke!)

        invite = UploadInvite.create!(
          account: @account,
          client: @client,
          purpose: :onboarding,
          period: nil,
          created_by_user: @user,
          token: UploadInvite.generate_token,
          expires_at: 90.days.from_now
        )

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "upload_invite.created",
          subject: invite,
          metadata: { client_id: @client.id, purpose: "onboarding" }
        )

        invite
      end
    end
  end
end

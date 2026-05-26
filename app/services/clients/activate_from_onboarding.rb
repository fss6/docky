# frozen_string_literal: true

module Clients
  class ActivateFromOnboarding
    def self.call(client:, user: nil, automatic: false, account: nil)
      new(client: client, user: user, automatic: automatic, account: account).call
    end

    def initialize(client:, user:, automatic:, account:)
      @client = client
      @user = user
      @automatic = automatic
      @account = account || client.account
    end

    def call
      return @client if @client.active?

      Client.transaction do
        checklist = @client.onboarding_checklist
        checklist&.update!(status: :completed, completed_at: Time.current)

        revoke_onboarding_invites!

        @client.update!(status: :active)

        Periods::OpenForClient.call(
          client: @client,
          period: Date.current.beginning_of_month,
          account: @account
        )

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.activated_from_onboarding",
          subject: @client,
          metadata: { automatic: @automatic }
        )

        OnboardingMailer.client_activated(@client).deliver_later if @client.email.present?
      end

      @client
    end

    private

    def revoke_onboarding_invites!
      UploadInvite.purpose_onboarding.where(client: @client, revoked_at: nil).find_each(&:revoke!)
    end
  end
end

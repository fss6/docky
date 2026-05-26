# frozen_string_literal: true

module Clients
  class ReopenOnboarding
    def self.call(client:, user:, account: ActsAsTenant.current_tenant)
      new(client: client, user: user, account: account).call
    end

    def initialize(client:, user:, account:)
      @client = client
      @user = user
      @account = account
    end

    def call
      Client.transaction do
        checklist = @client.onboarding_checklist
        unless checklist
          checklist = Onboarding::BuildFromTemplate.call(
            client: @client,
            onboarding_kind: @client.onboarding_kind.presence || "new_client",
            account: @account
          )
        end

        checklist.update!(
          status: :in_progress,
          completed_at: nil,
          started_at: checklist.started_at || Time.current
        )

        @client.update!(status: :onboarding)

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.onboarding_reopened",
          subject: @client,
          metadata: {}
        )

        @client
      end
    end
  end
end

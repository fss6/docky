# frozen_string_literal: true

module Clients
  class CreateWithOnboarding
    def self.call(client:, onboarding_kind:, user:, account: ActsAsTenant.current_tenant)
      new(client: client, onboarding_kind: onboarding_kind, user: user, account: account).call
    end

    def initialize(client:, onboarding_kind:, user:, account:)
      @client = client
      @onboarding_kind = onboarding_kind.to_s
      @user = user
      @account = account
    end

    def call
      Client.transaction do
        if @onboarding_kind == "skipped"
          @client.status = :active
          @client.onboarding_kind = "skipped"
          @client.save!
          Periods::OpenForClient.call(
            client: @client,
            period: Date.current.beginning_of_month,
            account: @account
          )
        else
          @client.status = :onboarding
          @client.onboarding_kind = @onboarding_kind
          @client.save!
          Onboarding::BuildFromTemplate.call(
            client: @client,
            onboarding_kind: @onboarding_kind,
            account: @account
          )
        end

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.created",
          subject: @client,
          metadata: { status: @client.status, onboarding_kind: @onboarding_kind }
        )

        @client
      end
    end
  end
end

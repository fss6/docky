# frozen_string_literal: true

module Clients
  class StartOnboarding
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
      raise ArgumentError, "Cliente já está em onboarding" if @client.onboarding?

      Client.transaction do
        @client.update!(status: :onboarding, onboarding_kind: @onboarding_kind)

        checklist = @client.onboarding_checklist
        if checklist
          checklist.update!(status: :in_progress, completed_at: nil, onboarding_kind: @onboarding_kind)
          checklist.items.update_all(state: :pending, last_document_id: nil, validated_by_user_id: nil, received_at: nil, validated_at: nil)
        else
          Onboarding::BuildFromTemplate.call(
            client: @client,
            onboarding_kind: @onboarding_kind,
            account: @account
          )
        end

        Onboarding::EnsureClientFolder.call(client: @client, account: @account)

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.onboarding_started",
          subject: @client,
          metadata: { onboarding_kind: @onboarding_kind }
        )

        @client
      end
    end
  end
end

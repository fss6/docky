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
          template = resolve_template
          checklist = Onboarding::BuildFromTemplate.call(
            client: @client,
            template: template,
            account: @account
          )
        end

        checklist.update!(
          status: :in_progress,
          completed_at: nil,
          started_at: checklist.started_at || Time.current
        )

        @client.update!(status: :onboarding)

        Onboarding::EnsureClientFolder.call(client: @client, account: @account)

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

    private

    def resolve_template
      @client.onboarding_template ||
        OnboardingTemplate.default_for_client_creation(@account) ||
        raise(ActiveRecord::RecordNotFound, "Nenhum template de onboarding disponível")
    end
  end
end

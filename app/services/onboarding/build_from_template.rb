# frozen_string_literal: true

module Onboarding
  class BuildFromTemplate
    def self.call(client:, onboarding_kind:, account: client.account)
      new(client: client, onboarding_kind: onboarding_kind, account: account).call
    end

    def initialize(client:, onboarding_kind:, account:)
      @client = client
      @onboarding_kind = onboarding_kind
      @account = account
    end

    def call
      template_kind = OnboardingTemplate.kind_for_onboarding_kind(@onboarding_kind)
      template = OnboardingTemplate.find_by!(account: @account, kind: template_kind)

      checklist = OnboardingChecklist.create!(
        account: @account,
        client: @client,
        onboarding_kind: @onboarding_kind,
        status: :in_progress,
        started_at: Time.current
      )

      template.items.ordered.each_with_index do |template_item, index|
        checklist.items.create!(
          name: template_item.name,
          help_text: template_item.help_text,
          position: index,
          state: :pending
        )
      end

      EnsureClientFolder.call(client: @client, account: @account)

      checklist
    end
  end
end

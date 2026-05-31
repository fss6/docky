# frozen_string_literal: true

module Onboarding
  class BuildFromTemplate
    def self.call(client:, template:, account: client.account)
      new(client: client, template: template, account: account).call
    end

    def initialize(client:, template:, account:)
      @client = client
      @template = template
      @account = account
    end

    def call
      checklist = OnboardingChecklist.create!(
        account: @account,
        client: @client,
        onboarding_template: @template,
        status: :in_progress,
        started_at: Time.current
      )

      @template.items.ordered.each_with_index do |template_item, index|
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

# frozen_string_literal: true

module Clients
  class CreateWithOnboarding
    SKIPPED_VALUE = "skipped"

    def self.call(client:, onboarding_template_id:, user:, account: ActsAsTenant.current_tenant)
      new(client: client, onboarding_template_id: onboarding_template_id, user: user, account: account).call
    end

    def initialize(client:, onboarding_template_id:, user:, account:)
      @client = client
      @onboarding_template_id = onboarding_template_id.to_s
      @user = user
      @account = account
    end

    def call
      validate_onboarding_selection!

      Client.transaction do
        if skip_onboarding?
          @client.status = :active
          @client.onboarding_template = nil
          @client.save!
          Periods::OpenForClient.call(
            client: @client,
            period: Date.current.beginning_of_month,
            account: @account
          )
        else
          template = @account.onboarding_templates.find(@onboarding_template_id)
          @client.status = :onboarding
          @client.onboarding_template = template
          @client.save!
          Onboarding::BuildFromTemplate.call(
            client: @client,
            template: template,
            account: @account
          )
        end

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.created",
          subject: @client,
          metadata: audit_metadata
        )

        @client
      end
    end

    private

    def skip_onboarding?
      @onboarding_template_id == SKIPPED_VALUE
    end

    def validate_onboarding_selection!
      return if skip_onboarding?
      return if @onboarding_template_id.present? && @account.onboarding_templates.exists?(@onboarding_template_id)

      @client.errors.add(:base, "Selecione o tipo de onboarding")
      raise ActiveRecord::RecordInvalid, @client
    end

    def audit_metadata
      if skip_onboarding?
        { status: @client.status, onboarding_skipped: true }
      else
        {
          status: @client.status,
          onboarding_template_id: @client.onboarding_template_id,
          onboarding_template_name: @client.onboarding_template.name
        }
      end
    end
  end
end

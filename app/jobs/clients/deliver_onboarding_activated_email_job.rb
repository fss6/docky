# frozen_string_literal: true

module Clients
  class DeliverOnboardingActivatedEmailJob < ApplicationJob
    queue_as :mailers

    discard_on ActiveRecord::RecordNotFound

    def perform(client_id:, user_id: nil, automatic: false)
      client = Client.find(client_id)
      account = client.account
      user = User.find_by(id: user_id)

      ActsAsTenant.with_tenant(account) do
        unless deliverable?(client)
          Rails.logger.info(
            "[DeliverOnboardingActivatedEmailJob] skipped client=#{client.id} " \
            "active=#{client.active?} email_present=#{client.email.present?}"
          )
          return
        end

        OnboardingMailer.client_activated(client).deliver_now

        record_audit(
          account: account,
          user: user,
          event_type: "client.onboarding_email_sent",
          subject: client,
          metadata: audit_metadata(client, automatic: automatic)
        )
      end
    rescue StandardError => e
      if defined?(client) && client&.account
        record_audit(
          account: client.account,
          user: user,
          event_type: "client.onboarding_email_failed",
          subject: client,
          metadata: audit_metadata(client, automatic: automatic).merge(
            error_class: e.class.name,
            error_message: e.message.to_s.truncate(500)
          )
        )
      end
      raise
    end

    private

    def deliverable?(client)
      client.active? && client.email.present?
    end

    def audit_metadata(client, automatic:)
      {
        client_id: client.id,
        period: Date.current.beginning_of_month.strftime("%Y-%m"),
        recipient: client.email,
        automatic: automatic
      }
    end

    def record_audit(account:, user:, event_type:, subject:, metadata:)
      AuditEvents::Recorder.call(
        account: account,
        user: user,
        event_type: event_type,
        subject: subject,
        metadata: metadata
      )
    end
  end
end

# frozen_string_literal: true

module Clients
  class DeliverUploadInviteEmailJob < ApplicationJob
    queue_as :mailers

    discard_on ActiveRecord::RecordNotFound

    def perform(upload_invite_id:, user_id:)
      invite = UploadInvite.find(upload_invite_id)
      client = invite.client
      account = invite.account
      user = User.find_by(id: user_id)

      ActsAsTenant.with_tenant(account) do
        unless deliverable?(invite, client)
          Rails.logger.info(
            "[DeliverUploadInviteEmailJob] skipped invite=#{invite.id} " \
            "active=#{invite.active?} email_present=#{client.email.present?}"
          )
          return
        end

        setting = account.setting || account.create_setting!
        upload_url = PublicUploadUrl.for(token: invite.token)
        rendered = UploadShareMessageRenderer.call(
          setting: setting,
          client: client,
          url: upload_url,
          period: invite.period
        )

        UploadInviteMailer.share_link(
          client: client,
          invite: invite,
          email_subject: rendered.email_subject,
          email_body: rendered.email_body,
          upload_url: upload_url,
          account_name: account.name
        ).deliver_now

        record_audit(
          account: account,
          user: user,
          event_type: "upload_invite.email_sent",
          subject: invite,
          metadata: audit_metadata(invite, client)
        )
      end
    rescue StandardError => e
      if defined?(invite) && invite&.account
        record_audit(
          account: invite.account,
          user: user,
          event_type: "upload_invite.email_failed",
          subject: invite,
          metadata: audit_metadata(invite, invite.client).merge(
            error_class: e.class.name,
            error_message: e.message.to_s.truncate(500)
          )
        )
      end
      raise
    end

    private

    def deliverable?(invite, client)
      invite.active? && client.email.present?
    end

    def audit_metadata(invite, client)
      {
        client_id: client.id,
        period: invite.period.strftime("%Y-%m"),
        recipient: client.email
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

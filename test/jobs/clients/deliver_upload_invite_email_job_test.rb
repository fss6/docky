# frozen_string_literal: true

require "test_helper"

module Clients
  class DeliverUploadInviteEmailJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper
    setup do
      @user = users(:owner)
      @account = accounts(:one)
      @client = clients(:alpha)
      ActsAsTenant.with_tenant(@account) do
        @account.setting || @account.create_setting!
        @invite = UploadInvite.create!(
          account: @account,
          client: @client,
          period: Date.current.beginning_of_month,
          token: UploadInvite.generate_token,
          expires_at: 30.days.from_now
        )
      end
    end

    test "perform delivers mail and records email_sent audit" do
      assert_difference -> { AuditEvent.where(event_type: "upload_invite.email_sent").count }, 1 do
        assert_emails 1 do
          DeliverUploadInviteEmailJob.perform_now(
            upload_invite_id: @invite.id,
            user_id: @user.id
          )
        end
      end

      event = AuditEvent.order(:id).last
      assert_equal "upload_invite.email_sent", event.event_type
      assert_equal @client.email, event.metadata["recipient"]
    end

    test "perform records email_failed when delivery raises" do
      delivery = mock("message_delivery")
      delivery.stubs(:deliver_now).raises(StandardError, "SMTP timeout")
      UploadInviteMailer.stubs(:share_link).returns(delivery)

      assert_raises(StandardError, "SMTP timeout") do
        DeliverUploadInviteEmailJob.perform_now(
          upload_invite_id: @invite.id,
          user_id: @user.id
        )
      end

      event = AuditEvent.order(:id).last
      assert_equal "upload_invite.email_failed", event.event_type
      assert_includes event.metadata["error_message"], "SMTP timeout"
    end

    test "perform skips inactive invite without audit" do
      ActsAsTenant.with_tenant(@account) { @invite.revoke! }

      assert_no_difference -> { AuditEvent.count } do
        assert_no_emails do
          DeliverUploadInviteEmailJob.perform_now(
            upload_invite_id: @invite.id,
            user_id: @user.id
          )
        end
      end
    end
  end
end

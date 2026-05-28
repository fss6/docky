# frozen_string_literal: true

require "test_helper"

module Clients
  class DeliverOnboardingActivatedEmailJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper
    include OnboardingTestHelper

    setup do
      @user = users(:owner)
      @client = create_onboarding_client
      ActsAsTenant.with_tenant(@client.account) do
        Clients::ActivateFromOnboarding.call(
          client: @client,
          user: @user,
          account: @client.account
        )
      end
      @client.reload
    end

    test "perform delivers mail and records onboarding_email_sent audit" do
      assert_difference -> { AuditEvent.where(event_type: "client.onboarding_email_sent").count }, 1 do
        assert_emails 1 do
          DeliverOnboardingActivatedEmailJob.perform_now(
            client_id: @client.id,
            user_id: @user.id,
            automatic: false
          )
        end
      end

      event = AuditEvent.order(:id).last
      assert_equal "client.onboarding_email_sent", event.event_type
      assert_equal @client.email, event.metadata["recipient"]
    end

    test "perform records onboarding_email_failed when delivery raises" do
      delivery = mock("message_delivery")
      delivery.stubs(:deliver_now).raises(StandardError, "SMTP refused")
      OnboardingMailer.stubs(:client_activated).returns(delivery)

      assert_raises(StandardError, "SMTP refused") do
        DeliverOnboardingActivatedEmailJob.perform_now(
          client_id: @client.id,
          user_id: @user.id,
          automatic: false
        )
      end

      event = AuditEvent.order(:id).last
      assert_equal "client.onboarding_email_failed", event.event_type
      assert_includes event.metadata["error_message"], "SMTP refused"
    end
  end
end

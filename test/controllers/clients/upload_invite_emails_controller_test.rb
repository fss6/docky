# frozen_string_literal: true

require "test_helper"

module Clients
  class UploadInviteEmailsControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      @user = users(:owner)
      sign_in @user
      @client = clients(:alpha)
      @period = Date.current.beginning_of_month
      @invite = ActsAsTenant.with_tenant(accounts(:one)) do
        UploadInvite.create!(
          account: accounts(:one),
          client: @client,
          period: @period,
          token: UploadInvite.generate_token,
          expires_at: 30.days.from_now
        )
      end
    end

    test "send_email enqueues job when client has email" do
      assert_no_difference -> { AuditEvent.count } do
        assert_enqueued_with(job: DeliverUploadInviteEmailJob) do
          post send_email_client_upload_invite_path(@client, @invite),
               headers: { Accept: "application/json" }
        end
      end

      assert_response :success
      body = JSON.parse(response.body)
      assert_includes body["message"], "Envio em andamento"
      assert_includes body["message"], @client.email
    end

    test "send_email returns unprocessable when client email is blank" do
      client_without_email = clients(:beta)
      client_without_email.update_column(:email, nil)

      invite = ActsAsTenant.with_tenant(accounts(:one)) do
        UploadInvite.create!(
          account: accounts(:one),
          client: client_without_email,
          period: @period,
          token: UploadInvite.generate_token,
          expires_at: 30.days.from_now
        )
      end

      assert_no_enqueued_jobs only: DeliverUploadInviteEmailJob do
        post send_email_client_upload_invite_path(client_without_email, invite),
             headers: { Accept: "application/json" }
      end

      assert_response :unprocessable_entity
      body = JSON.parse(response.body)
      assert_includes body["error"], "e-mail"
    end
  end
end

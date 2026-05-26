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

    test "send_email enqueues mail when client has email" do
      assert_enqueued_emails 1 do
        post send_email_client_upload_invite_path(@client, @invite),
             headers: { Accept: "application/json" }
      end

      assert_response :success
      body = JSON.parse(response.body)
      assert_includes body["message"], @client.email
    end

    test "send_email returns unprocessable when client email is blank" do
      client_without_email = clients(:beta)

      invite = ActsAsTenant.with_tenant(accounts(:one)) do
        UploadInvite.create!(
          account: accounts(:one),
          client: client_without_email,
          period: @period,
          token: UploadInvite.generate_token,
          expires_at: 30.days.from_now
        )
      end

      assert_no_enqueued_emails do
        post send_email_client_upload_invite_path(client_without_email, invite),
             headers: { Accept: "application/json" }
      end

      assert_response :unprocessable_entity
      body = JSON.parse(response.body)
      assert_includes body["error"], "e-mail"
    end
  end
end

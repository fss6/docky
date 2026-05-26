# frozen_string_literal: true

require "test_helper"

class UploadInvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @client = clients(:alpha)
    @period = Date.current.beginning_of_month.strftime("%Y-%m")
  end

  test "create html redirects and always creates new invite" do
    existing = ActsAsTenant.with_tenant(accounts(:one)) do
      UploadInvite.create!(
        account: accounts(:one),
        client: @client,
        period: Date.current.beginning_of_month,
        token: UploadInvite.generate_token,
        expires_at: 30.days.from_now
      )
    end

    assert_difference -> { UploadInvite.count }, 1 do
      post client_upload_invites_path(@client, period: @period)
    end

    assert_redirected_to client_path(@client, aba: "convites", period: @period)
    existing.reload
    assert existing.revoked_at.present?
  end

  test "create json reuses active invite" do
    invite = ActsAsTenant.with_tenant(accounts(:one)) do
      UploadInvite.create!(
        account: accounts(:one),
        client: @client,
        period: Date.current.beginning_of_month,
        token: UploadInvite.generate_token,
        expires_at: 30.days.from_now
      )
    end

    assert_no_difference -> { UploadInvite.count } do
      post client_upload_invites_path(@client, period: @period),
           headers: { Accept: "application/json" }
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_includes body["html"], invite.token
    assert_includes body["html"], "WhatsApp"
    assert_includes body["html"], "Enviar e-mail"
  end

  test "create turbo_stream reuses active invite" do
    invite = ActsAsTenant.with_tenant(accounts(:one)) do
      UploadInvite.create!(
        account: accounts(:one),
        client: @client,
        period: Date.current.beginning_of_month,
        token: UploadInvite.generate_token,
        expires_at: 30.days.from_now
      )
    end

    assert_no_difference -> { UploadInvite.count } do
      post client_upload_invites_path(@client, period: @period),
           headers: { Accept: "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match invite.token, response.body
    assert_match "WhatsApp", response.body
  end

  test "create json creates invite with expires_at" do
    assert_difference -> { UploadInvite.count }, 1 do
      post client_upload_invites_path(@client, period: @period),
           headers: { Accept: "application/json" }
    end

    invite = UploadInvite.order(:created_at).last
    assert invite.expires_at.present?
    assert invite.expires_at > 29.days.from_now
    assert_response :success
    body = JSON.parse(response.body)
    assert_includes body["html"], "share_link_modal_content"
    assert_includes body["html"], invite.token
  end
end

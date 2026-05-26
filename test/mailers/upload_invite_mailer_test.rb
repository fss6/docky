# frozen_string_literal: true

require "test_helper"

class UploadInviteMailerTest < ActionMailer::TestCase
  setup do
    @account = accounts(:one)
    ActsAsTenant.with_tenant(@account) do
      @setting = @account.setting || @account.create_setting!
      @client = clients(:alpha)
      @invite = UploadInvite.create!(
        account: @account,
        client: @client,
        period: Date.current.beginning_of_month,
        token: UploadInvite.generate_token,
        expires_at: 30.days.from_now
      )
    end
    @url = "https://app.example.com/public/folders/token/upload"
    @rendered = UploadShareMessageRenderer.call(
      setting: @setting,
      client: @client,
      url: @url,
      period: @invite.period
    )
  end

  test "share_link uses configured subject and body" do
    custom_subject = "Assunto custom — {{nome_cliente}}"
    custom_body = "Corpo com {{link}} e {{competencia}}"
    ActsAsTenant.with_tenant(@account) do
      @setting.update!(
        upload_share_email_subject_template: custom_subject,
        upload_share_email_body_template: custom_body
      )
      @rendered = UploadShareMessageRenderer.call(
        setting: @setting.reload,
        client: @client,
        url: @url,
        period: @invite.period
      )
    end

    mail = UploadInviteMailer.share_link(
      client: @client,
      invite: @invite,
      email_subject: @rendered.email_subject,
      email_body: @rendered.email_body,
      upload_url: @url,
      account_name: @account.name
    )

    assert_equal [ @client.email ], mail.to
    assert_includes mail.subject, @client.name
    assert_includes mail.html_part.body.decoded, @url
    assert_includes mail.text_part.body.decoded, @url
  end
end

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
    custom_body = "Corpo para {{nome_cliente}} com {{link}} e {{competencia}}"
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

    html = mail.html_part.body.decoded
    text = mail.text_part.body.decoded

    assert_includes html, I18n.t("mailers.upload_invite.before_cta")
    assert_includes html, I18n.t("mailers.upload_invite.cta")
    assert_includes html, I18n.t("mailers.upload_invite.link_fallback")
    assert_includes html, I18n.t("mailers.upload_invite.platform_footer")
    assert_includes html, "href=\"#{@url}\""
    assert_includes html, "<strong"
    assert_includes html, ERB::Util.html_escape(@client.name)
    assert_includes html, ERB::Util.html_escape(@account.name)
    assert_includes html, MailerHelper::DOKIVO_BRAND_COLOR
    assert_not_includes html, I18n.t("mailers.layout.footer")

    assert_includes text, @url
    assert_includes text, @account.name
    assert_includes text, I18n.t("mailers.upload_invite.platform_footer")
    assert_not_includes text, Setting::LINK_PLACEHOLDER
  end
end

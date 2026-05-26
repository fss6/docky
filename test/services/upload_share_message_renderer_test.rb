# frozen_string_literal: true

require "test_helper"

class UploadShareMessageRendererTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    ActsAsTenant.with_tenant(@account) do
      @setting = @account.setting || @account.create_setting!
      @client = clients(:alpha)
    end
    @period = Date.new(2026, 5, 1)
    @url = "https://app.example.com/public/folders/abc/upload"
  end

  test "interpolates placeholders" do
    ActsAsTenant.with_tenant(@account) do
      @setting.update!(
        upload_share_whatsapp_template: "Olá {{nome_cliente}} — {{competencia}}: {{link}}",
        upload_share_email_subject_template: "Docs {{nome_cliente}}",
        upload_share_email_body_template: "Link: {{link}} para {{competencia}}"
      )

      result = UploadShareMessageRenderer.call(
        setting: @setting,
        client: @client,
        url: @url,
        period: @period
      )

      assert_includes result.whatsapp_text, @client.name
      assert_includes result.whatsapp_text, @url
      assert_includes result.whatsapp_text, "Maio/2026"

      assert_equal "Docs #{@client.name}", result.email_subject
      assert_includes result.email_body, @url
      assert_includes result.email_body, "Maio/2026"
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class MailerHelperTest < ActionView::TestCase
  include MailerHelper

  test "strip_link_from_email_body removes url and link-only lines" do
    url = "https://app.example.com/upload"
    body = <<~TEXT.strip
      Olá,

      Envie documentos pelo link abaixo:

      #{url}

      Obrigado.
    TEXT

    result = strip_link_from_email_body(body, url)

    assert_not_includes result, url
    assert_includes result, "Obrigado"
    assert_not_includes result.downcase, "link abaixo"
  end

  test "upload_invite_email_body_html highlights client and period" do
    client = clients(:alpha)
    period = Date.new(2026, 5, 1)
    body = "Documentos de #{client.name} em Maio/2026."

    html = upload_invite_email_body_html(body, upload_url: "https://example.com", client: client, period: period)

    assert_includes html, "<strong"
    assert_includes html, ERB::Util.html_escape(client.name)
    assert_includes html, "Maio/2026"
  end
end

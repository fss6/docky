# frozen_string_literal: true

class UploadInviteMailer < ApplicationMailer
  def share_link(client:, invite:, email_subject:, email_body:, upload_url:, account_name:)
    @client = client
    @invite = invite
    @body = email_body
    @upload_url = upload_url
    @account_name = account_name

    mail(to: client.email, subject: email_subject)
  end
end

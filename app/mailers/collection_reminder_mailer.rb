# frozen_string_literal: true

class CollectionReminderMailer < ApplicationMailer
  def client_reminder(dispatch:, client:, upload_url:, unsubscribe_token:)
    @dispatch = dispatch
    @client = client
    @body = dispatch.rendered_body
    @upload_url = upload_url
    @unsubscribe_url = collection_unsubscribe_url(token: unsubscribe_token)

    mail(to: client.email, subject: dispatch.rendered_subject)
  end

  def internal_alert(dispatch:, recipient:)
    @dispatch = dispatch
    @client = dispatch.client
    @body = dispatch.rendered_body

    mail(to: recipient, subject: dispatch.rendered_subject)
  end
end

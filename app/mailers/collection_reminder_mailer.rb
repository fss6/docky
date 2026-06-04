# frozen_string_literal: true

class CollectionReminderMailer < ApplicationMailer
  def client_reminder(dispatch:, client:, upload_url:, unsubscribe_token:, to: nil, test_mode: false)
    @dispatch = dispatch
    @client = client
    @body = dispatch.rendered_body
    @upload_url = upload_url
    @unsubscribe_url = if test_mode
      "#{upload_url}#test-unsubscribe"
    else
      collection_unsubscribe_url(token: unsubscribe_token)
    end

    subject = dispatch.rendered_subject
    subject = "[TESTE] #{subject}" if to.present?

    mail(to: to || client.email, subject: subject)
  end

  def internal_alert(dispatch:, recipient:, to: nil)
    @dispatch = dispatch
    @client = dispatch.client
    @body = dispatch.rendered_body

    subject = dispatch.rendered_subject
    destination = to || recipient
    subject = "[TESTE] #{subject}" if to.present?

    mail(to: destination, subject: subject)
  end
end

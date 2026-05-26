# frozen_string_literal: true

class OnboardingMailer < ApplicationMailer
  def client_activated(client)
    @client = client
    @account = client.account
    @period_label = I18n.l(Date.current.beginning_of_month, format: "%B/%Y")

    mail(
      to: client.email,
      subject: "#{@account.name} — sua conta está pronta"
    )
  end
end

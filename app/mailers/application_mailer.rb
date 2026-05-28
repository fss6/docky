class ApplicationMailer < ActionMailer::Base
  helper MailerHelper

  default from: ENV.fetch("MAILER_FROM", "from@example.com")
  layout "mailer"
end

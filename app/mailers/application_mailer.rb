class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "prism@example.com")
  layout "mailer"
end

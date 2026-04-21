class ObserverMailer < ApplicationMailer
  # SMELL: Called via deliver_now inside ObservationSession#finalize!
  # Blocks the web request. Should be deliver_later via a job.
  # Also has no retry logic — if the SMTP server is down, the finalization
  # appears to succeed but the notification is silently lost.
  def session_finalized(observation_session)
    @session   = observation_session
    @observer  = observation_session.observer
    @classroom = observation_session.classroom
    @teacher   = observation_session.teacher

    mail(
      to:      @observer.user.email,
      subject: "Session finalized: #{@classroom.name} — #{@session.observed_on.strftime('%b %d, %Y')}"
    )
  end
end

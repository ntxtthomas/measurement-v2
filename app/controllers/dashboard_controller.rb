# =============================================================================
# DashboardController
#
# DELIBERATE HOTSPOT: N+1 query nightmare.
#
# The index action computes org-level stats by iterating over organizations,
# then schools, then classrooms — producing O(orgs × schools × classrooms)
# queries. At 5 orgs / 4 schools each / 5 classrooms each that's ~100 queries
# just to build @org_stats.
#
# HOW TO SEE IT: Run the app with Bullet enabled (it is, in development.rb).
# Every dashboard load will print N+1 warnings in the log.
#
# IMPROVEMENT PATH:
#   1. Add eager loading: Organization.includes(schools: { classrooms: [:students, :observation_sessions] })
#   2. Replace Ruby aggregation with a single GROUP BY SQL query
#   3. Add a materialized stats table or counter caches
#   4. Add Redis caching for the overall_average computation
#
# IDEAL / PROBLEM-SOLVING: Apply I-D-E-A-L:
#   Identify  → Bullet + slow query log shows N+1 on dashboard
#   Define    → avg dashboard load is 3s at 50 orgs, should be <200ms
#   Explore   → eager load? SQL rollup? cache?
#   Act       → implement chosen fix
#   Look back → benchmark before/after
# =============================================================================
class DashboardController < ApplicationController
  def index
    # SMELL: No eager loading. Each call below triggers additional queries.
    @organizations = Organization.active.order(:name)

    # SMELL: Computing stats entirely in Ruby — no SQL aggregation.
    # At 20 orgs this is already slow. At 200 it is unusable.
    @org_stats = @organizations.map do |org|
      schools = org.schools # N+1: one query per org

      session_count   = 0
      finalized_count = 0
      student_count   = 0

      schools.each do |school|
        classrooms = school.classrooms # N+1: one query per school

        classrooms.each do |classroom|
          student_count   += classroom.students.count           # N+1 per classroom
          sessions         = classroom.observation_sessions     # N+1 per classroom
          session_count   += sessions.count
          # SMELL: select(&:finalized?) loads all session objects into Ruby
          finalized_count += sessions.select(&:finalized?).count
        end
      end

      {
        org:             org,
        school_count:    schools.count,
        session_count:   session_count,
        finalized_count: finalized_count,
        student_count:   student_count
      }
    end

    # SMELL: Separate query for recent sessions — no eager loading, will N+1 in the view
    # (observer.user, classroom.school etc. all trigger extra queries when rendered)
    @recent_sessions = ObservationSession.order(created_at: :desc).limit(20)

    # SMELL: Loading ALL finalized sessions to compute overall average in Ruby.
    # Should be: ObservationSession.joins(:observation_scores).where(status: :finalized)
    #              .average("observation_scores.score")
    all_finalized = ObservationSession.where(status: :finalized)
    @overall_average = if all_finalized.any?
      all_finalized.map { |s|
        s.observation_scores.sum(:score).to_f / [s.observation_scores.count, 1].max
      }.sum.to_f / all_finalized.count
    else
      0
    end

    # SMELL: COUNT(*) on the full table every request — no caching
    @total_sessions = ObservationSession.count
    @total_students = Student.count
    @total_finalized = ObservationSession.where(status: :finalized).count
  end
end

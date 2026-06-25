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
    # SMELL: Computing stats entirely in Ruby — no SQL aggregation.
    # At 20 orgs this is already slow. At 200 it is unusable.
    # REFACTORED: Now using single GROUP BY query with DISTINCT counts to avoid row multiplication
    @org_stats = Organization.active
                  .joins(schools: { classrooms: [:students, :observation_sessions] })
                  .group("organizations.id", "organizations.name")
                  .select(
                    "organizations.*",
                    "COUNT(DISTINCT schools.id) AS school_count",
                    "COUNT(DISTINCT students.id) AS student_count",
                    "COUNT(DISTINCT observation_sessions.id) AS session_count",
                    "COUNT(DISTINCT CASE WHEN observation_sessions.status = 2 THEN observation_sessions.id END) AS finalized_count"
                  )
                  .order(:name)
                  .map do |row|
                    {
                      org: row,
                      school_count: row.school_count,
                      session_count: row.session_count,
                      finalized_count: row.finalized_count,
                      student_count: row.student_count
                    }
                  end

    # SMELL: Separate query for recent sessions — no eager loading, will N+1 in the view
    # (observer.user, classroom.school etc. all trigger extra queries when rendered)
    # @recent_sessions = ObservationSession.order(created_at: :desc).limit(20)
    @recent_sessions = ObservationSession.includes(observer: :user, classroom: :school)
                            .order(created_at: :desc)
                            .limit(20)

    ave = ObservationSession.joins(:observation_scores)
                            .where(status: :finalized)
                            .average("observation_scores.score")
    @overall_average = ave || 0

    # SMELL: COUNT(*) on the full table every request — no caching
    @total_sessions = ObservationSession.count
    @total_students = Student.count
    @total_finalized = ObservationSession.where(status: :finalized).count
  end
end

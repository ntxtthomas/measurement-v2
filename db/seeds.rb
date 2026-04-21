# =============================================================================
# Seeds
#
# Generates a realistic dataset sized to expose N+1s, dashboard pressure,
# and report-generation slowness.
#
# Approximate output:
#   5  organizations
#   20 schools  (4 per org)
#   80 classrooms (4 per school)
#   80 teachers   (1 per classroom for simplicity)
#   ~1,600 students (20 per classroom)
#   ~3 observers per org = 15 observers
#   ~5 sessions per classroom = ~400 sessions
#   ~8 scores per session = ~3,200 scores
#   ~3 notes per session  = ~1,200 notes
#   ~0.4 note-student links per note = ~480 note_students
#   7 engineering phases with full epic/story/task tree
#
# Runtime: ~60–120 seconds locally. Use FAST_SEED=1 for a smaller dataset.
# =============================================================================

require "faker"

fast_seed = ENV["FAST_SEED"] == "1"

puts "Cleaning database..."
[
  ObservationNoteStudent, ObservationNote, ObservationScore,
  Report, ObservationSession, Student, Classroom, Teacher,
  Observer, User, School, Organization,
  Task, Story, Epic, Phase
].each(&:delete_all)

# ── Observation Dimensions (canonical, seeded once) ──────────────────────────
puts "Seeding observation dimensions..."

DIMENSIONS = [
  { name: "Learning Climate",        code: "LC", category: "Emotional Support",     description: "Warmth, respect, and positive connections in the classroom.", position: 1 },
  { name: "Behavioral Guidance",     code: "BG", category: "Emotional Support",     description: "Proactive, consistent approaches to supporting student behavior.", position: 2 },
  { name: "Student Engagement",      code: "SE", category: "Classroom Organization", description: "Degree to which students are actively involved in learning activities.", position: 3 },
  { name: "Learning Facilitation",   code: "LF", category: "Classroom Organization", description: "Smooth, efficient transitions and use of instructional time.", position: 4 },
  { name: "Instructional Dialogue",  code: "ID", category: "Instructional Support",  description: "Quality of back-and-forth discussion that extends student thinking.", position: 5 },
  { name: "Content Understanding",   code: "CU", category: "Instructional Support",  description: "Depth and accuracy of content presented and explored.", position: 6 },
  { name: "Critical Inquiry",        code: "CI", category: "Instructional Support",  description: "Questions and activities that promote higher-order thinking.", position: 7 },
  { name: "Feedback Loops",          code: "FL", category: "Instructional Support",  description: "Quality and specificity of feedback provided to students.", position: 8 },
].freeze

dimensions = DIMENSIONS.map { |attrs| ObservationDimension.create!(attrs.merge(min_score: 1, max_score: 7)) }

puts "  Created #{dimensions.count} dimensions"

# ── Organizations ─────────────────────────────────────────────────────────────
puts "Seeding organizations..."

org_names = [
  "Northbridge Learning Alliance",
  "Southside Education Collaborative",
  "Westfield Child Development Network",
  "Eastmore Public Schools",
  "Central Valley Unified Initiative"
]

organizations = org_names.map.with_index do |name, i|
  Organization.create!(
    name:          name,
    slug:          name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, ""),
    contact_email: "admin@#{name.split.first.downcase}.edu",
    status:        "active"
  )
end

puts "  Created #{organizations.count} organizations"

# ── Users + Observers ─────────────────────────────────────────────────────────
puts "Seeding users and observers..."

# Admin user
admin = User.create!(
  email:         "admin@prism.local",
  password:      "password",
  first_name:    "Admin",
  last_name:     "User",
  role:          "admin",
  active:        true
)

observers = []

organizations.each do |org|
  3.times do
    user = User.create!(
      email:      Faker::Internet.unique.email,
      password:   "password",
      first_name: Faker::Name.first_name,
      last_name:  Faker::Name.last_name,
      role:       "observer",
      active:     true
    )
    observers << Observer.create!(
      user:                user,
      organization:        org,
      certification_level: %w[standard standard advanced master trainee].sample,
      certified_on:        Faker::Date.between(from: 3.years.ago, to: 1.year.ago),
      active:              true
    )
  end
end

puts "  Created #{observers.count} observers"

# ── Schools ───────────────────────────────────────────────────────────────────
puts "Seeding schools..."

school_count = fast_seed ? 2 : 4
schools = []

organizations.each do |org|
  school_count.times do
    schools << School.create!(
      organization: org,
      name:         "#{Faker::Address.city} #{%w[Elementary Middle High].sample} School",
      address:      Faker::Address.street_address,
      city:         Faker::Address.city,
      state:        Faker::Address.state_abbr,
      status:       "active"
    )
  end
end

puts "  Created #{schools.count} schools"

# ── Teachers + Classrooms + Students ─────────────────────────────────────────
puts "Seeding teachers, classrooms, students..."

classroom_count   = fast_seed ? 2 : 4
students_per_room = fast_seed ? 10 : 20

all_classrooms = []
all_teachers   = []

schools.each do |school|
  classroom_count.times do
    teacher = Teacher.create!(
      school:       school,
      first_name:   Faker::Name.first_name,
      last_name:    Faker::Name.last_name,
      email:        Faker::Internet.unique.email,
      grade_levels: %w[K 1st 2nd 3rd 4th 5th 6th 7th 8th 9th 10th 11th 12th].sample(2).join(","),
      total_sessions: 0,
      average_score_cache: nil
    )
    all_teachers << teacher

    grade = %w[K 1st 2nd 3rd 4th 5th 6th 7th 8th].sample
    classroom = Classroom.create!(
      school:      school,
      teacher:     teacher,
      name:        "#{teacher.last_name}'s #{grade} Grade",
      grade_level: grade,
      subject:     %w[Reading Math Science Social\ Studies ELA].sample
    )
    all_classrooms << classroom

    students_per_room.times do
      Student.create!(
        classroom:        classroom,
        first_name:       Faker::Name.first_name,
        last_name:        Faker::Name.last_name,
        date_of_birth:    Faker::Date.between(from: 12.years.ago, to: 5.years.ago),
        student_id_number: Faker::Alphanumeric.alphanumeric(number: 8).upcase
      )
    end
  end
end

puts "  Created #{all_classrooms.count} classrooms, #{all_teachers.count} teachers, #{Student.count} students"

# ── Observation Sessions + Scores + Notes ────────────────────────────────────
puts "Seeding observation sessions..."

sessions_per_classroom = fast_seed ? 3 : 5
notes_per_session      = fast_seed ? 2 : 3

all_sessions = []

all_classrooms.each do |classroom|
  org_observers = observers.select { |o| o.organization_id == classroom.school.organization_id }

  sessions_per_classroom.times do |i|
    observer  = org_observers.sample
    status    = i == 0 ? :in_progress : :finalized
    observed_on = Faker::Date.between(from: 6.months.ago, to: 1.week.ago)

    session = ObservationSession.new(
      observer:    observer,
      classroom:   classroom,
      teacher:     classroom.teacher,
      observed_on: observed_on,
      status:      status
    )

    if status == :finalized
      session.finalized_at    = (observed_on.to_time + rand(1..4).hours).utc
      session.finalized_by_id = observer.user_id
    end

    session.save!(validate: false)  # skip validation to allow seeding without all scores
    all_sessions << session

    # ── Scores ──────────────────────────────────────────────────────────────
    dimensions.each do |dim|
      # Score skewed toward mid-range (realistic classroom distribution)
      score = [1, 1, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 7].sample
      ObservationScore.create!(
        observation_session:   session,
        observation_dimension: dim,
        score:                 score
      )
    end

    session.update_column(:notes_count_cache, notes_per_session)

    # ── Notes ────────────────────────────────────────────────────────────────
    students = classroom.students.to_a

    notes_per_session.times do
      note = ObservationNote.create!(
        observation_session: session,
        observer:            observer,
        content:             Faker::Lorem.sentences(number: rand(1..3)).join(" ")
      )

      # ~40% of notes tagged to 1–2 students
      if rand < 0.4 && students.any?
        students.sample(rand(1..2)).each do |student|
          ObservationNoteStudent.create!(observation_note: note, student: student)
        end
      end
    end

    # ── Report for finalized sessions ────────────────────────────────────────
    if status == :finalized
      Report.create!(
        observation_session: session,
        generated_by:        observer.user_id,
        status:              :complete,
        content: {
          generated_at:   session.finalized_at.iso8601,
          organization:   classroom.school.organization.name,
          school:         classroom.school.name,
          overall_average: rand(3.0..6.5).round(2)
        }.to_json
      )
    end
  end
end

# Update teacher stats (normally done by callbacks, but we bypassed validation above)
puts "Updating teacher stat caches..."
Teacher.find_each do |teacher|
  finalized = teacher.observation_sessions.where(status: :finalized)
  avg_scores = ObservationScore.where(observation_session: finalized).average(:score)
  teacher.update_columns(
    total_sessions:      finalized.count,
    average_score_cache: avg_scores&.to_f&.round(2)
  )
end

puts "  Created #{all_sessions.count} sessions, #{ObservationScore.count} scores, #{ObservationNote.count} notes"

# ── Engineering Phases / Epics / Stories / Tasks ──────────────────────────────
puts "Seeding engineering improvement tracker..."

engineering_data = [
  {
    name: "Bugs", color: "#dc2626", position: 1,
    description: "Known defects that need fixing before improvement work begins.",
    epics: [
      {
        name: "Data Integrity", description: "Fix missing constraints and invalid data paths.",
        stories: [
          {
            name: "Duplicate scores per dimension",
            description: "Add unique index on (observation_session_id, observation_dimension_id) to prevent duplicate scores.",
            tasks: [
              { name: "Write failing test demonstrating duplicate score save", status: :not_started },
              { name: "Write migration: unique index on observation_scores", status: :not_started },
              { name: "Add uniqueness validation to ObservationScore model", status: :not_started },
              { name: "Verify seed data has no duplicates", status: :not_started }
            ]
          },
          {
            name: "Non-unique student_id_number",
            description: "student_id_number has no uniqueness constraint — duplicate students can be created.",
            tasks: [
              { name: "Add unique index migration on students.student_id_number", status: :not_started },
              { name: "Handle or deduplicate existing duplicate data in seeds", status: :not_started }
            ]
          }
        ]
      }
    ]
  },
  {
    name: "Performance", color: "#f97316", position: 2,
    description: "Query optimization, N+1 elimination, missing indexes.",
    epics: [
      {
        name: "Dashboard N+1 Queries", description: "Eliminate the N+1 query cascade on the main dashboard.",
        stories: [
          {
            name: "Add eager loading to dashboard index",
            description: "Use includes() to preload org → school → classroom → session data.",
            tasks: [
              { name: "Reproduce: enable Bullet, load dashboard, capture N+1 warnings", status: :not_started },
              { name: "Define: document query count before fix in problem-solving-journal.md", status: :not_started },
              { name: "Add includes() to DashboardController#index", status: :not_started },
              { name: "Replace Ruby aggregation with SQL GROUP BY query", status: :not_started },
              { name: "Verify: measure query count after fix", status: :not_started },
              { name: "Write regression spec: dashboard does not trigger N+1", status: :not_started }
            ]
          },
          {
            name: "Add missing indexes",
            description: "Add indexes on observation_sessions.status, observed_on, and observer_id + status composite.",
            tasks: [
              { name: "Write migration: index on observation_sessions.status", status: :not_started },
              { name: "Write migration: index on observation_sessions.observed_on", status: :not_started },
              { name: "Write migration: composite (observer_id, status)", status: :not_started },
              { name: "Write migration: unique (observation_session_id, observation_dimension_id) on scores", status: :not_started },
              { name: "Benchmark before/after with EXPLAIN ANALYZE", status: :not_started }
            ]
          }
        ]
      },
      {
        name: "Report Generation N+1", description: "Fix N+1 loops inside GenerateReportJob and build_report_content.",
        stories: [
          {
            name: "Preload associations in GenerateReportJob",
            description: "Use includes(:observation_dimension) on scores and includes(:students) on notes.",
            tasks: [
              { name: "Identify all N+1 loops in GenerateReportJob#build_content", status: :not_started },
              { name: "Add includes to score query", status: :not_started },
              { name: "Add includes to note query", status: :not_started },
              { name: "Test with rack-mini-profiler query count", status: :not_started }
            ]
          }
        ]
      }
    ]
  },
  {
    name: "Refactor", color: "#8b5cf6", position: 3,
    description: "Fat model/controller extraction, duplication removal, naming improvements.",
    epics: [
      {
        name: "Extract Finalization Logic", description: "Decompose ObservationSession#finalize! into a service object.",
        stories: [
          {
            name: "Extract FinalizeObservationSession service",
            description: "Move state transition, score validation, report trigger, and notification out of the model.",
            tasks: [
              { name: "Apply Bloodhound Q3: identify all concerns in finalize!", status: :not_started },
              { name: "Write specs for current finalize! behavior as a safety net", status: :not_started },
              { name: "Create app/services/finalize_observation_session.rb", status: :not_started },
              { name: "Move score validation logic to service", status: :not_started },
              { name: "Move report trigger to service", status: :not_started },
              { name: "Move mailer call to service", status: :not_started },
              { name: "Update controller to call service", status: :not_started },
              { name: "Delete or slim finalize! on model — verify tests pass", status: :not_started }
            ]
          }
        ]
      },
      {
        name: "Consolidate Score Classification", description: "Remove triplicated classify_score logic.",
        stories: [
          {
            name: "Create ScoreLevel value object or module",
            description: "Single source of truth for Concern/Mixed/Strong classification.",
            tasks: [
              { name: "Identify all three classify_score implementations", status: :not_started },
              { name: "Document differences in docs/refactors/README.md", status: :not_started },
              { name: "Create ScoreLevel module in app/models/concerns/", status: :not_started },
              { name: "Replace all three usages", status: :not_started },
              { name: "Add tests for ScoreLevel", status: :not_started }
            ]
          }
        ]
      },
      {
        name: "Fix Law of Demeter Violations", description: "Stop reaching through 3-hop association chains in views and models.",
        stories: [
          {
            name: "Delegate organization_name / school_name on ObservationSession",
            description: "Use delegate or introduce query methods that don't chain through 3 models.",
            tasks: [
              { name: "List all LoD violations in models and views", status: :not_started },
              { name: "Add delegation methods on ObservationSession", status: :not_started },
              { name: "Update views to use delegated methods", status: :not_started }
            ]
          }
        ]
      }
    ]
  },
  {
    name: "Reliability", color: "#0ea5e9", position: 4,
    description: "Idempotency, error handling, retry safety.",
    epics: [
      {
        name: "Idempotent Report Generation", description: "Make GenerateReportJob safe to retry.",
        stories: [
          {
            name: "Add idempotency guard to GenerateReportJob",
            description: "Check for existing complete report before creating a new one.",
            tasks: [
              { name: "Reproduce: manually retry job, observe duplicate Report rows", status: :not_started },
              { name: "Add guard: return if complete Report exists for session", status: :not_started },
              { name: "Add unique index on reports.observation_session_id or use advisory lock", status: :not_started },
              { name: "Write spec: job called twice creates only one complete report", status: :not_started }
            ]
          }
        ]
      },
      {
        name: "Async Finalization Flow", description: "Move synchronous work in finalize! to Sidekiq.",
        stories: [
          {
            name: "Use deliver_later for observer notifications",
            description: "Replace deliver_now with deliver_later to stop blocking the request.",
            tasks: [
              { name: "Change ObserverMailer call to deliver_later", status: :not_started },
              { name: "Verify notifications are enqueued not delivered in test suite", status: :not_started }
            ]
          },
          {
            name: "Move report generation to background job",
            description: "Replace synchronous generate_report_synchronously! with GenerateReportJob.perform_later.",
            tasks: [
              { name: "Update finalize! to enqueue GenerateReportJob instead of calling synchronously", status: :not_started },
              { name: "Update finalize controller action to handle async response", status: :not_started },
              { name: "Add Turbo Stream or polling for report ready status", status: :not_started }
            ]
          }
        ]
      }
    ]
  },
  {
    name: "Scaling", color: "#10b981", position: 5,
    description: "Pagination, bulk writes, caching, database query optimization.",
    epics: [
      {
        name: "Pagination", description: "Add Kaminari pagination where missing.",
        stories: [
          {
            name: "Paginate observation sessions index",
            description: "ObservationSessionsController#index loads all sessions — add .page(params[:page]).per(25).",
            tasks: [
              { name: "Add pagination to sessions index", status: :not_started },
              { name: "Add pagination to classrooms#show sessions list", status: :not_started },
              { name: "Add pagination to teachers#show sessions list", status: :not_started },
              { name: "Add pagination to reports index", status: :not_started }
            ]
          }
        ]
      },
      {
        name: "Bulk Score Writes", description: "Replace row-by-row score upsert with upsert_all.",
        stories: [
          {
            name: "Refactor score submission to upsert_all",
            description: "The finalize controller loops over scores with find_or_initialize_by + save — replace with ObservationScore.upsert_all.",
            tasks: [
              { name: "Write benchmark test: row-by-row vs bulk for 8 scores", status: :not_started },
              { name: "Implement upsert_all in ObservationSessionsController#finalize", status: :not_started },
              { name: "Wrap score + note writes in a transaction", status: :not_started },
              { name: "Verify idempotency: submit same scores twice", status: :not_started }
            ]
          }
        ]
      },
      {
        name: "Dashboard Caching", description: "Cache aggregated stats to avoid full-table scans on every load.",
        stories: [
          {
            name: "Add Redis caching for org stats on dashboard",
            description: "Cache the org_stats computation for 5 minutes using Rails.cache.fetch.",
            tasks: [
              { name: "Configure Redis cache store in production.rb", status: :not_started },
              { name: "Wrap @org_stats computation in Rails.cache.fetch with 5min expiry", status: :not_started },
              { name: "Add cache invalidation on ObservationSession finalization", status: :not_started },
              { name: "Load test dashboard before/after", status: :not_started }
            ]
          }
        ]
      }
    ]
  },
  {
    name: "Security", color: "#f59e0b", position: 6,
    description: "Authorization, input sanitization, safe redirects.",
    epics: [
      {
        name: "Authorization", description: "Replace inline auth checks with a policy layer.",
        stories: [
          {
            name: "Extract authorization to policy objects",
            description: "Inline owned_by_current_observer? checks in controllers — extract to ObservationSessionPolicy.",
            tasks: [
              { name: "Audit all inline auth checks across controllers", status: :not_started },
              { name: "Create ObservationSessionPolicy", status: :not_started },
              { name: "Apply policy to sessions controller", status: :not_started },
              { name: "Apply policy to reports controller", status: :not_started },
              { name: "Write policy specs", status: :not_started }
            ]
          }
        ]
      }
    ]
  },
  {
    name: "Observability", color: "#64748b", position: 7,
    description: "Logging, monitoring hooks, Sidekiq visibility.",
    epics: [
      {
        name: "Structured Logging", description: "Add structured log context to key operations.",
        stories: [
          {
            name: "Add request ID and user ID to all log lines",
            description: "Use Rails tagged logging or Lograge to add context to every log line.",
            tasks: [
              { name: "Install and configure Lograge", status: :not_started },
              { name: "Add user_id and observer_id to log tags", status: :not_started },
              { name: "Add timing log to observation finalization", status: :not_started },
              { name: "Add timing log to report generation job", status: :not_started }
            ]
          }
        ]
      }
    ]
  }
].freeze

engineering_data.each do |phase_data|
  phase = Phase.create!(
    name:        phase_data[:name],
    description: phase_data[:description],
    position:    phase_data[:position],
    color:       phase_data[:color]
  )

  phase_data[:epics].each.with_index(1) do |epic_data, ei|
    epic = Epic.create!(
      phase:       phase,
      name:        epic_data[:name],
      description: epic_data[:description],
      position:    ei
    )

    epic_data[:stories].each.with_index(1) do |story_data, si|
      story = Story.create!(
        epic:        epic,
        name:        story_data[:name],
        description: story_data[:description],
        position:    si
      )

      story_data[:tasks].each.with_index(1) do |task_data, ti|
        Task.create!(
          story:    story,
          name:     task_data[:name],
          status:   task_data[:status],
          position: ti
        )
      end
    end
  end
end

puts "  Created #{Phase.count} phases, #{Epic.count} epics, #{Story.count} stories, #{Task.count} tasks"

# ── Summary ────────────────────────────────────────────────────────────────────
puts ""
puts "=" * 60
puts "Seed complete!"
puts "  Organizations : #{Organization.count}"
puts "  Schools       : #{School.count}"
puts "  Classrooms    : #{Classroom.count}"
puts "  Teachers      : #{Teacher.count}"
puts "  Students      : #{Student.count}"
puts "  Observers     : #{Observer.count}"
puts "  Sessions      : #{ObservationSession.count}"
puts "  Scores        : #{ObservationScore.count}"
puts "  Notes         : #{ObservationNote.count}"
puts "  Reports       : #{Report.count}"
puts ""
puts "  Admin login   : admin@prism.local / password"
puts "  Any observer  : <any seeded email> / password"
puts "=" * 60

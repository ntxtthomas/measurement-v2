# Scaling and Refactoring Roadmap

## Guiding Principle

Make it work. Make it right. Make it fast — in that order.

The engineering phases in the app dashboard reflect this order. Don't jump to caching before you've fixed the N+1 queries. Don't add Redis before you understand what the actual query problem is.

---

## Phase 1: Bugs (Start Here)

Fix the data integrity problems first. Code improvements on a broken foundation are noise.

**Key tasks**:
- Add unique index on `(observation_session_id, observation_dimension_id)` for scores
- Add uniqueness validation on `ObservationScore`
- Address `student_id_number` uniqueness

---

## Phase 2: Performance — Query Optimization

**Step 1: Reproduce**
- Enable Bullet
- Load the dashboard
- Run `bin/rails db:seed` and browse all the main pages
- Record every N+1 warning

**Step 2: Fix the Dashboard**
Replace:
```ruby
# Before: O(n) queries per org
@org_stats = @organizations.map { |org| ... org.schools.each ... }
```
With:
```ruby
# After: 1 query using eager loading + SQL rollup
@organizations = Organization.active
                   .includes(schools: { classrooms: [:students, :observation_sessions] })
                   .order(:name)
```
Or better: a single summary query:
```ruby
Organization.joins(schools: { classrooms: :observation_sessions })
            .group("organizations.id")
            .select("organizations.*, COUNT(DISTINCT classrooms.id) AS classroom_count, ...")
```

**Step 3: Add Missing Indexes**
```ruby
add_index :observation_sessions, :status
add_index :observation_sessions, :observed_on
add_index :observation_sessions, [:observer_id, :status]
```

**Step 4: Fix Notes N+1**
```ruby
# In sessions#show:
@notes = @session.observation_notes.includes(:students)
```

---

## Phase 3: Refactor — Fat Model Extraction

The `finalize!` method violates SRP. Extract to a service:

```ruby
# app/services/finalize_observation_session.rb
class FinalizeObservationSession
  def initialize(session, current_user)
    @session = session
    @user = current_user
  end

  def call
    validate_scores! &&
      transition_status! &&
      enqueue_report! &&
      enqueue_notification! &&
      update_teacher_stats!
  end
end
```

Principles applied: SRP, Tell Don't Ask, CQS, Composition over Inheritance

**Refactoring session template** (from Bloodhound Questions):
1. How will this look to a fresh pair of eyes? → 100-line method in a model
2. Is too much going on in one spot? → Yes (state, validation, report, email, stats)
3. Is it hard to change? → Yes (callbacks, tight coupling to mailer)
4. Is it brutally imperative? → Yes — good candidate for service decomposition
5. What code smells are present? → Long method, SRP violation, LoD

---

## Phase 4: Reliability

**Fix GenerateReportJob idempotency**:
```ruby
def perform(observation_session_id)
  session = ObservationSession.find(observation_session_id)
  # Guard: skip if already complete
  return if Report.complete.exists?(observation_session: session)
  # ... rest of job
end
```

**Move email to background**:
```ruby
# Before (blocks request):
ObserverMailer.session_finalized(self).deliver_now

# After:
ObserverMailer.session_finalized(self).deliver_later
```

**Move report generation to Sidekiq**:
```ruby
# In FinalizeObservationSession service:
GenerateReportJob.perform_later(session.id)
```

---

## Phase 5: Scaling

**Pagination** (Kaminari is already in Gemfile):
```ruby
@sessions = @session.observation_sessions.order(...).page(params[:page]).per(25)
```

**Bulk score writes**:
```ruby
# Before: 8 × (SELECT + INSERT/UPDATE)
params[:scores].each { |id, val| score.save! }

# After: 1 database call
ObservationScore.upsert_all(score_rows, unique_by: [:observation_session_id, :observation_dimension_id])
```

**Dashboard caching**:
```ruby
@org_stats = Rails.cache.fetch("dashboard_org_stats", expires_in: 5.minutes) do
  compute_org_stats  # extracted method
end
```

---

## Scaling Targets and Order of Operations

| Users | Key Concern | Suggested Fix |
|-------|------------|---------------|
| 0–100 | App works | Seeds, test coverage, basic correctness |
| 100–500 | Slow dashboard | N+1 fix, eager loading, indexes |
| 500–2,000 | Report generation slowness | Async Sidekiq job, idempotency |
| 2,000–10,000 | DB under write pressure | Bulk writes, transaction boundaries |
| 10,000–50,000 | Dashboard at scale | Redis caching, SQL rollup tables |
| 50,000–200,000 | Job queue pressure | Job sharding, priority queues |
| 200,000–1M | Read bottlenecks | Read replicas, CDN, denormalized stats tables |

---

## DRY Violation Cleanup: Score Classification

Three independent `classify_score` implementations:
- `ObservationSession#classify_score` → Concern / Mixed / Strong
- `GenerateReportJob#classify_score` → same
- `ObservationHelper#display_score_level` → slight variation

**Fix**:
```ruby
# app/models/concerns/score_classification.rb
module ScoreClassification
  LEVELS = [
    { range: 1..2, label: "Concern", css: "concern" },
    { range: 3..5, label: "Mixed",   css: "mixed" },
    { range: 6..7, label: "Strong",  css: "strong" },
  ].freeze

  def self.for(score)
    LEVELS.find { |l| l[:range].include?(score) } || { label: "Unknown", css: "" }
  end
end
```

Include in model: `include ScoreClassification` — or use as a plain module.

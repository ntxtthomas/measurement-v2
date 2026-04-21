# Hotspots, Smells, and Improvement Strategy

## Why Deliberate Flaws?

Prism is a practice app. The flaws are not accidents — they are realistic problems that commonly appear in early-stage Rails apps. They exist so you can:

1. **Reproduce** the problem (often a slow page or a failing job)
2. **Diagnose** with real tools (Bullet, EXPLAIN ANALYZE, logs)
3. **Fix** with a well-reasoned approach
4. **Verify** the fix with benchmarks or tests
5. **Document** what you learned

---

## Hotspot 1: Dashboard N+1 Query Cascade

**File**: `app/controllers/dashboard_controller.rb`, `app/views/dashboard/index.html.erb`

**What happens**: `DashboardController#index` loads `Organization.active`, then for each org loads schools, for each school loads classrooms, for each classroom loads students and sessions. This produces O(orgs × schools × classrooms) queries.

At seed data scale (5 orgs × 4 schools × 4 classrooms = 80 classrooms), this generates ~170 queries per dashboard load.

**Why it was included**: This is the most common first N+1 problem developers encounter. It requires understanding eager loading, SQL aggregation, and the trade-off between code clarity and performance.

**How to see it**: Enable Bullet in `config/environments/development.rb` (already done). Load the dashboard. Bullet will print N+1 warnings.

**Improvement path**:
1. Add `includes()` to the org query
2. Replace Ruby aggregation with SQL GROUP BY
3. Add Redis caching for stat results
4. Add counter caches on models

---

## Hotspot 2: Fat ObservationSession Model

**File**: `app/models/observation_session.rb`

**What happens**: The model has 200+ lines. `finalize!` does: state validation, score validation (N+1 loop), status update, report generation (synchronous), email (synchronous + `deliver_now`), teacher stat update. All callbacks fire on every save.

**Smells present**:
- SRP violation: one method does 6 things
- Law of Demeter: `classroom.school.organization.name`
- Magic numbers: score range 1–7 in 3 places
- Duplicate average calculation: `average_score` vs `overall_average`
- `after_save :recalculate_teacher_session_count` fires on every save, not just finalization
- `deliver_now` blocks the request

**Why it was included**: Fat models are the canonical Rails anti-pattern. They happen when the model is the only available location for business logic. The fix is a service object (`FinalizeObservationSession`) that extracts the responsibilities.

**Bloodhound questions to apply here**: Q1, Q3, Q6, Q7, Q8, Q12

---

## Hotspot 3: Non-Idempotent GenerateReportJob

**File**: `app/jobs/generate_report_job.rb`

**What happens**: The job creates a `Report` record, generates content, marks it complete. If the job is retried (Sidekiq default: 3 retries on failure), it creates a second `Report` row before any guard stops it. Because `raise e` re-raises on failure, retries keep creating new `:generating` rows.

**Why it was included**: Non-idempotent jobs are a classic reliability problem. They look fine in development (where retries rarely happen) but create data quality problems in production under load. The fix requires understanding idempotency, unique constraints, and advisory locks.

**Improvement path**:
1. Add: `return if Report.where(observation_session: session, status: [:complete, :generating]).exists?`
2. Add unique index on `reports.observation_session_id`
3. Use `discard_on` instead of `raise e` for unretryable failures
4. Add `sidekiq_options retry: false` or idempotency key

---

## Hotspot 4: Student-Linked Notes — N+1 and Law of Demeter

**Files**: `app/views/observation_sessions/show.html.erb`, `app/controllers/students_controller.rb`, `app/models/observation_note.rb`

**What happens**: Session show view renders notes. For each note, `note.students.any?` and `note.students.map(&:full_name)` fire a query per note. In the student show view, each note triggers a chain: `note.observation_session.observed_on` and `note.observer.user.full_name`.

**Why it was included**: Join-table N+1 is a less obvious form of the problem. It requires understanding `includes` across has_many :through associations and thinking about eager loading across multiple hops.

**Improvement path**:
1. In controller: `@notes = @session.observation_notes.includes(:students)`
2. In student show: `@notes = @student.observation_notes.includes(:observation_session, observer: :user)`

---

## Smell Index

| Smell | Location | Severity |
|-------|----------|----------|
| N+1 queries | Dashboard, session show, student show, report job | High |
| Missing indexes | `observation_sessions.status`, `observed_on` | High |
| Fat model | `ObservationSession` | High |
| Long method | `finalize!`, `build_report_content` | High |
| Non-idempotent job | `GenerateReportJob` | High |
| DRY violation (classify_score) | Model + Job + Helper — 3 implementations | Medium |
| Law of Demeter | `classroom.school.organization.name` throughout | Medium |
| Magic numbers | Score range 1–7 in 3 files | Medium |
| Synchronous I/O in request | `deliver_now`, inline report generation | Medium |
| Stale cache | `notes_count_cache`, `average_score_cache` | Medium |
| No pagination | Sessions index, classroom show, teacher show | Low → Medium at scale |
| Inline authorization | `owned_by_current_observer?` in controller | Low |
| Comma-separated column | `teacher.grade_levels` | Low (but blocks filtering) |

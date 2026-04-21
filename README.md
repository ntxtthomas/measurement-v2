# Prism — Education Observation Platform

> Observe. Measure. Improve.

Prism is a **deliberate practice Rails application** built to serve as a domain-relevant engineering lab. It is **intentionally imperfect**: it works at small scale but contains realistic performance, reliability, and architecture debt that surfaces as load increases, making it a rich target for debugging, refactoring, performance work, and scaling exercises.

---

## Why This App Exists

Most "practice" Rails apps are either toy CRUD demos (too simple to expose real problems) or they start with clean architecture that has nothing to improve. Prism is different:

- It is a **believable early-stage internal product** — the kind of thing a small team would ship in a sprint
- It contains **specific, documented flaws** placed intentionally to create learning opportunities
- It supports **phased improvement** through a built-in engineering dashboard that tracks the work
- It is designed to let you practice the full engineering lifecycle: reproduce → debug → refactor → test → deploy

---

## Domain Overview

Prism models an **education observation and measurement platform** for classroom quality. An observer visits a classroom, records scores across structured dimensions, captures notes (optionally tagging individual students), and finalizes the session. Reports are generated and aggregated across organizations, schools, and teachers.

### Entities

| Entity | Description |
|--------|-------------|
| `Organization` | Top-level grouping (district, network) |
| `School` | Site within an organization |
| `Classroom` | Room with a grade, subject, and teacher |
| `Teacher` | Instructor assigned to a classroom |
| `Student` | Enrolled in a classroom |
| `User` | Authenticated system user |
| `Observer` | A user who conducts observations |
| `ObservationDimension` | A scoring category (e.g., Learning Climate) |
| `ObservationSession` | The core event: observer + classroom + teacher + date |
| `ObservationScore` | One score per dimension per session |
| `ObservationNote` | Free-text note, optionally linked to students |
| `Report` | Generated artifact from a finalized session |
| `Phase / Epic / Story / Task` | Engineering improvement tracker |

### Original Observation Dimensions

Not a copy of CLASS™ or any proprietary framework. Prism uses 8 original dimensions across 3 domains:

**Emotional Support**: Learning Climate (LC), Behavioral Guidance (BG)  
**Classroom Organization**: Student Engagement (SE), Learning Facilitation (LF)  
**Instructional Support**: Instructional Dialogue (ID), Content Understanding (CU), Critical Inquiry (CI), Feedback Loops (FL)

Scores 1–7. Classification: Concern (1–2), Mixed (3–5), Strong (6–7).

---

## Tech Stack

| Tool | Role |
|------|------|
| Ruby 3.2.2 / Rails 7.1 | Application framework |
| PostgreSQL 15 | Primary database |
| Redis 7 | Cache and Sidekiq backend |
| Sidekiq 7 | Background jobs |
| Hotwire / Turbo | Minimal frontend interactivity |
| RSpec + FactoryBot | Testing |
| Bullet | N+1 detection in development |
| rack-mini-profiler | Query profiling in development |
| Kaminari | Pagination (intentionally missing from some hotspots) |
| Docker Compose | Local infrastructure (optional) |

---

## Setup

### Prerequisites

- Ruby 3.2.2 (`rbenv` or `rvm`)
- PostgreSQL 15
- Redis 7
- Bundler

### Local Setup

```bash
git clone <repo>
cd measurement

# Install gems
bundle install

# Copy and configure environment
cp .env.example .env

# Create and migrate database
bin/rails db:create db:migrate

# Seed data (~1,600 students, ~400 sessions, 7 engineering phases)
bin/rails db:seed

# Start server + Sidekiq
bin/dev
```

Visit `http://localhost:3000`  
Sign in: `admin@prism.local` / `password`

### With Docker Compose

```bash
docker compose up -d db redis
bin/rails db:create db:migrate db:seed
bin/dev
```

### Fast Seed (smaller dataset)

```bash
FAST_SEED=1 bin/rails db:seed
```

---

## Key Workflows

1. Sign in → main dashboard (org rollup, recent sessions)
2. Navigate org → school → classroom → start session
3. Record scores per dimension (1–7)
4. Add notes, optionally tag students
5. Finalize session (scores committed, report generated, notification sent)
6. View report and session history
7. Engineering dashboard: track phases/epics/stories/tasks, update task status

---

## Intentional Hotspot Areas

These are the deliberate pain points. Each has inline code comments explaining the flaw and the improvement path.

### 1. Dashboard (`DashboardController#index`, `dashboard/index.html.erb`)

- N+1 query cascade: org → schools → classrooms → students/sessions each trigger separate queries
- Ruby aggregation instead of SQL GROUP BY
- No caching — full table scans on every page load
- N+1 in the view when rendering `@recent_sessions`

### 2. Observation Finalization (`ObservationSession#finalize!`, `ObservationSessionsController#finalize`)

- `finalize!` is 100+ lines and does: state check, score validation, report generation, mailer, teacher stats
- Row-by-row score upsert (8 × SELECT + INSERT/UPDATE per finalization)
- Synchronous report generation blocks the request
- `deliver_now` for email blocks the request
- No race condition protection against two simultaneous finalizations

### 3. Report Generation (`GenerateReportJob`)

- Non-idempotent: retries create duplicate `Report` rows
- N+1 loops: `score.observation_dimension.name` per score, `note.students.map` per note
- Re-raises after partial failure, triggering retry that creates another row
- Magic numbers duplicated from model and helper

### 4. Student-Linked Notes (`ObservationNote`, views, `StudentsController`)

- N+1: `note.students.any?` per note in session show view
- N+1: `note.observation_session.classroom` chain in student show view
- No eager loading anywhere in the note rendering path
- Law of Demeter violations throughout

---

## Engineering Dashboard

Navigate to `/engineering` to see the improvement tracker.

7 phases are pre-seeded with epics, stories, and tasks:

| Phase | Focus |
|-------|-------|
| Bugs | Data integrity defects |
| Performance | N+1 queries, missing indexes, slow aggregation |
| Refactor | Fat model/controller extraction, DRY violations |
| Reliability | Idempotency, async jobs, error handling |
| Scaling | Pagination, bulk writes, caching |
| Security | Authorization policies, input safety |
| Observability | Structured logging, monitoring hooks |

Each task has a status (not_started / in_progress / blocked / done). Update status inline. Phase progress bars update accordingly.

Use this dashboard to visibly track your phased improvement effort.

---

## Observability Notes

The app does **not** integrate external observability tools — intentionally. Hooks are described here for when you're ready:

| Tool | Where to Add |
|------|-------------|
| Skylight | `Gemfile` + `config/application.rb` |
| Honeybadger | `Gemfile` + initializer for error tracking |
| New Relic | Agent in `Gemfile` + `config/newrelic.yml` |
| Lograge | Already listed as optional in `Gemfile`; enable in production.rb |

Built-in tooling is already configured:
- **Bullet** (development): logs N+1 warnings to console and adds footer banners
- **rack-mini-profiler** (development): shows query count/timing in top-left corner
- **Sidekiq Web UI**: mount at `/sidekiq` behind auth when needed

---

## How to Use This App for Practice

### Phase 0: Understand the system
- Read the wiki (`/wiki/`)
- Run the seed, explore the UI
- Enable Bullet and load the dashboard — watch the N+1 warnings
- Use rack-mini-profiler to see query counts

### Phase 1: Reproduce and document
- Use `docs/debugging-log.md` to record what you observe
- Use `docs/problem-solving-journal.md` (I-D-E-A-L format)

### Phase 2: Write a failing test
- Before fixing anything, write a spec that characterizes the broken/slow behavior
- This becomes your regression guard

### Phase 3: Fix, refactor, improve
- Apply the improvement from the engineering dashboard task list
- Use `docs/refactors/README.md` to document the decision

### Phase 4: Measure
- Compare query counts before/after
- Run `EXPLAIN ANALYZE` on slow queries
- Run the test suite to confirm no regressions

### Phase 5: Update the tracker
- Mark the engineering task as `done`
- Move to the next task

---

## Methodology References

See `docs/methods.md` for:
- **R-S-I-H-E-V-L** debugging method
- **I-D-E-A-L** problem-solving method
- **The 12 Bloodhound Questions** for refactoring
- Design principles (SOLID, DRY, YAGNI, LoD, etc.)

---

## License

MIT. See `LICENSE`.

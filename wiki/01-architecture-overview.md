# Architecture Overview

## What is Prism?

Prism is a Rails 7.1 monolith. It follows conventional Rails layering: models handle persistence and domain logic, controllers handle HTTP, views render HTML. There is no service layer, no CQRS, no event sourcing. This is intentional — the starting architecture is familiar and approachable. The complexity is in the data and the workflows, not the infrastructure.

## High-Level Stack

```
Browser → Puma (Rails 7.1) → PostgreSQL 15
                           → Redis → Sidekiq
```

- No microservices
- No GraphQL
- Hotwire/Turbo for light interactivity
- Sidekiq for background jobs (report generation, notifications)
- Docker Compose for local infrastructure (optional)

## Directory Structure

```
app/
  models/         Domain objects + persistence
  controllers/    HTTP request handling
  views/          ERB templates
  jobs/           Sidekiq background jobs
  helpers/        View helpers (some with intentional duplication)
  mailers/        Email delivery

db/
  migrate/        17 migrations (some with intentional missing indexes)
  seeds.rb        Generates realistic dataset

spec/
  models/         Unit tests for core domain logic
  requests/       Integration tests for key workflows
  factories/      FactoryBot definitions
```

## Key Architectural Decisions (and their trade-offs)

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| Fat model (ObservationSession) | Realistic early-stage code — everything in one place | Hard to test, hard to change, slow callbacks |
| Synchronous report generation | Simple to ship | Blocks request, non-idempotent on retry |
| No authorization library | Fewer dependencies | Inline auth checks, hard to audit |
| Comma-separated grade_levels | Fast to build | Not queryable, breaks filtering |
| Denormalized teacher_id on session | Convenient for queries | Can drift from classroom.teacher |
| notes_count_cache maintained manually | Avoids COUNT queries | Gets stale on note deletion |

## Current Limitations

- No tenant isolation (all observers see all data after auth)
- No pagination in several list views
- No background processing for report generation (it's inline in `finalize!`)
- No caching layer — every dashboard load is a full set of queries
- No rate limiting or abuse protection

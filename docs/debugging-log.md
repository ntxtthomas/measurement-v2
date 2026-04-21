# Debugging Log

Use this file to record debugging investigations. One entry per bug or performance issue.

---

## Template

```
## [YYYY-MM-DD] — Title

### R — Reproduce
- How did you find this? (Bullet warning / slow request / failing test / user report)
- Steps to reliably reproduce:
  1.
  2.
- Environment: dev / test / prod

### S — Simplify
- What is the minimal case that still shows the problem?
- Can you reproduce in a unit test?
- What can you remove and still see the issue?

### I — Inspect
- What do you observe? (log output, query count, stack trace, test failure)
- Paste relevant log lines or EXPLAIN ANALYZE output here:
  ```
  ```
- What queries are being made?

### H — Hypothesize
- What do you think is causing this?
- Why? What evidence supports this hypothesis?
- Alternative hypotheses:

### E — Experiment
- What did you change?
- What did you expect to happen?
- What actually happened?

### V — Verify
- Does the fix hold under the original reproduction case?
- Query count before: ___ After: ___
- Relevant test output:

### L — Learn
- What did you learn?
- Is there a pattern here you've seen before?
- What would you do differently on the next sprint?
- Link to refactor log or task update:
```

---

## Example Entry

## [2024-01-20] — Dashboard N+1: org stats table

### R — Reproduce
Found from Bullet footer warning: "USE eager loading detected: Organization => [:schools]"
Steps: sign in, load dashboard `/`.

### S — Simplify
Reproduced in a test: create 3 orgs, each with 3 schools. Dashboard makes 13 queries.

### I — Inspect
Bullet log output:
```
N+1 Query: Organization#schools
N+1 Query: School#classrooms
N+1 Query: Classroom#students
N+1 Query: Classroom#observation_sessions
```

### H — Hypothesize
`DashboardController#index` loads `Organization.all` without eager loading,
then iterates in Ruby calling `org.schools` per org, `school.classrooms` per school, etc.

### E — Experiment
Added `Organization.active.includes(schools: { classrooms: [:students, :observation_sessions] })`
Query count dropped from 83 to 4 with seed data.

### V — Verify
Test passes. Query count confirmed via rack-mini-profiler.

### L — Learn
Classic N+1. The fix is always eager loading or SQL aggregation.
The dashboard still has no caching — that's a Phase 5 task.

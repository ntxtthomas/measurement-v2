# Problem Solving Journal

Use I-D-E-A-L to structure engineering decisions and investigations.

---

## Template

```
## [YYYY-MM-DD] — Problem Title

### I — Identify
- What problem am I solving?
- How do I know it's a problem? (metric, user report, observation)
- Is this the real problem, or a symptom of something else?

### D — Define
- What does "solved" look like? (quantifiable target)
- What constraints apply? (time, risk, dependencies)
- What is out of scope?

### E — Explore
- Option A: ...
  - Pros:
  - Cons:
- Option B: ...
  - Pros:
  - Cons:
- Option C: ...
  - Pros:
  - Cons:
- Which option and why?

### A — Act
- What did I do?
- Files changed:
- Key decisions made during implementation:

### L — Look Back
- Did it work? (before/after metrics or test results)
- What surprised me?
- What would I do differently?
- What did this reveal about the codebase?
- Tasks updated in engineering dashboard:
```

---

## Example Entry

## [2024-01-22] — Report generation blocks request

### I — Identify
Finalization requests take 2–4 seconds. Users experience a freeze between clicking
"Finalize" and seeing the success page. Investigation showed `build_report_content`
runs synchronously inside `finalize!` and includes N+1 loops plus JSON construction.

### D — Define
Success = finalization completes in < 300ms.
The report can be generated asynchronously; users are OK waiting for it.
Out of scope for this sprint: real-time report status polling.

### E — Explore
- Option A: Move report generation to `GenerateReportJob.perform_later`
  - Pros: Fast, non-blocking, can retry
  - Cons: User doesn't see report immediately; need to handle "report pending" UI
- Option B: Cache report content on finalization, generate in background
  - Pros: Fast UI, data available
  - Cons: More complexity
- Option C: Keep synchronous but fix the N+1
  - Pros: Simple, report ready immediately
  - Cons: Still blocks request; still fails on timeout
- **Chose Option A** — simplest path to non-blocking; UI can poll or use Turbo Streams

### A — Act
- Extracted report generation from `finalize!` to `GenerateReportJob.perform_later(session.id)`
- Added `status: :pending` report row before enqueueing
- Updated finalize controller to redirect without waiting for report
- Session show page now checks report status and shows "Generating..." badge

### L — Look Back
Before: 2.8s average finalize request.
After: 180ms average. Report ready in 800ms–2s depending on Sidekiq load.
Discovered: `GenerateReportJob` is still non-idempotent (separate task).
Task updated: "Move report generation to background job" → done
Next: idempotency guard task.

# Engineering Methods Reference

This file documents the methods used to guide improvement work on Prism.
Apply these deliberately — pick one method and work it fully.

---

## Debugging: R-S-I-H-E-V-L

| Step | Name | Question |
|------|------|---------|
| R | Reproduce | Can I make it happen reliably? |
| S | Simplify | What is the minimal failing case? |
| I | Inspect | What does the evidence say? |
| H | Hypothesize | What do I think is causing this? |
| E | Experiment | What change will test my hypothesis? |
| V | Verify | Does the fix hold? |
| L | Learn | What do I now know that I didn't before? |

Use `docs/debugging-log.md` to record each step.

---

## Problem Solving: I-D-E-A-L

| Step | Name | Question |
|------|------|---------|
| I | Identify | What is the real problem? |
| D | Define | What does solved look like? |
| E | Explore | What are my options? |
| A | Act | What will I do and why? |
| L | Look Back | Did it work? What did I learn? |

Use `docs/problem-solving-journal.md` to record each step.

---

## Refactoring: The 12 Bloodhound Questions

Ask these before changing any code. Not every question applies every time.

1. **Fresh eyes** — How will this look to someone new?
2. **Squint test** — If I blur my eyes at the code, does the shape look right?
3. **Too much going on** — Is one method/class doing more than one thing?
4. **Unnamed concepts** — Is there something here that wants a name?
5. **Good names** — Do names reveal intent?
6. **Hard to change** — What would break if I changed this?
7. **Brutally imperative** — Is this a pile of steps when it could be objects doing simple things?
8. **Complex enough to merit change** — Is the pain real, or theoretical?
9. **Know enough today** — Do I understand the context well enough to refactor safely?
10. **Tells a story** — Does reading the code tell me what the system does?
11. **Laid out well** — Is the important stuff at the top? Is the structure legible?
12. **Code smells** — Which specific smells are present? (See list below)

Use `docs/refactors/README.md` to record refactoring decisions.

### Common Code Smells in This Codebase

- Long Method (`finalize!`, `build_report_content`)
- Fat Class (`ObservationSession`)
- Duplicate Code (`classify_score` in 3 places)
- Data Clumps (classroom + teacher + observer always appear together)
- Law of Demeter (`classroom.school.organization.name`)
- Magic Numbers (score range 1–7, cutoffs 2 and 5)
- Speculative Generality (none yet — keep it that way)
- Comments that apologize for the code

---

## Design Principles

Apply these deliberately. Don't apply all of them everywhere.

| Principle | When to apply in this codebase |
|-----------|-------------------------------|
| **SRP** | When extracting from `ObservationSession#finalize!` |
| **OCP** | When adding new report types or dimension categories |
| **DRY** | When consolidating `classify_score` implementations |
| **KISS** | Before adding any service, presenter, or pattern |
| **YAGNI** | Before adding any feature not asked for |
| **Law of Demeter** | When `a.b.c.d` appears in a model or view |
| **Tell, Don't Ask** | When a controller checks model state then acts on it |
| **CQS** | When a method both returns a value and has a side effect |
| **Fail Fast** | When adding validation to prevent invalid state from propagating |
| **Design for Testability** | When a method has too many collaborators to unit test cleanly |

---

## Observability Checklist

Before calling a fix "done":

- [ ] Can you measure the improvement? (query count, response time, error rate)
- [ ] Does the fix have test coverage?
- [ ] Is the fix logged/observable in production?
- [ ] Has the engineering dashboard task been updated?
- [ ] Has learnings been recorded in debugging-log or problem-solving-journal?

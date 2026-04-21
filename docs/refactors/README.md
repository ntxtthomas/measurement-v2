# Refactor Log

Use this file to record refactoring decisions. One entry per refactor.

---

## Template

```
## [YYYY-MM-DD] — Refactor Title

### Context
- Which file(s) were changed?
- Which engineering task does this address?
- Which Bloodhound question(s) triggered this refactor?

### Before (code sketch or description)
```ruby
# paste or describe the before state
```

### Problems identified
- Smell 1:
- Smell 2:

### After (code sketch or description)
```ruby
# paste or describe the after state
```

### Design principles applied
-

### Trade-offs
-

### Test coverage
- Tests added/updated:
- Before this refactor the tests showed:
- After this refactor the tests show:

### What I would do next
-
```

---

## Index of Completed Refactors

| Date | Title | Phase | Files Changed |
|------|-------|-------|---------------|
| — | (none yet) | — | — |

---

## Planned Refactors

These are tracked in the engineering dashboard but documented here for context.

| Title | Bloodhound Questions | Smells | Phase |
|-------|---------------------|--------|-------|
| Extract FinalizeObservationSession service | Q1, Q3, Q6, Q7 | Long method, SRP | Refactor |
| Consolidate ScoreClassification | Q4, Q5, Q12 | Duplicate code | Refactor |
| Fix Law of Demeter on ObservationSession | Q7, Q10 | LoD | Refactor |
| Add bulk score upsert | Q7 | Imperative loop | Scaling |
| Extract authorization to policy objects | Q6, Q12 | Feature envy | Security |

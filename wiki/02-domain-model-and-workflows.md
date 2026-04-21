# Domain Model and Key Workflows

## Entity Relationships

```
Organization
  └── School (many)
        └── Teacher (many, belongs_to school)
        └── Classroom (many, belongs_to school + teacher)
              └── Student (many)
              └── ObservationSession (many)
                    ├── ObservationScore (one per active Dimension)
                    ├── ObservationNote (many)
                    │     └── ObservationNoteStudent (join: note ↔ student)
                    └── Report (one per finalization — currently duplicatable)

Observer
  └── belongs_to User
  └── belongs_to Organization
  └── has_many ObservationSession
```

**Key denormalization**: `ObservationSession` stores both `classroom_id` and `teacher_id`. Since `Classroom belongs_to :teacher`, the teacher is already derivable. The direct `teacher_id` is a performance convenience that can drift.

## Observation Dimensions

8 original dimensions across 3 domains. Not a copy of any proprietary framework.

| Code | Name | Domain |
|------|------|--------|
| LC | Learning Climate | Emotional Support |
| BG | Behavioral Guidance | Emotional Support |
| SE | Student Engagement | Classroom Organization |
| LF | Learning Facilitation | Classroom Organization |
| ID | Instructional Dialogue | Instructional Support |
| CU | Content Understanding | Instructional Support |
| CI | Critical Inquiry | Instructional Support |
| FL | Feedback Loops | Instructional Support |

Scores are 1–7. Classification: Concern (1–2), Mixed (3–5), Strong (6–7).

## Key Workflows

### Start an Observation Session
1. Observer navigates: Dashboard → Organization → School → Classroom
2. Clicks "New Observation Session"
3. Selects classroom, teacher, date
4. Session created with `status: in_progress`

### Record Scores and Notes
- Observer visits session show page
- Records scores per dimension (radio buttons 1–7)
- Adds free-text notes, optionally tagging students from the classroom roster
- Notes are saved individually via form POSTs

### Finalize a Session
1. Observer clicks "Finalize Session"
2. Reviews and confirms scores on the finalize form
3. POST to `/observation_sessions/:id/finalize`
4. Controller writes scores row-by-row, then calls `session.finalize!(current_user)`
5. `finalize!` validates, sets status, generates report synchronously, sends email
6. Redirects to session show page

### Generate a Report
- Triggered synchronously inside `finalize!` (current behavior — intentional hotspot)
- `build_report_content` assembles JSON: session info, scores, category averages, notes
- Saved as a `Report` record
- Can be regenerated via "Regenerate Report" button → enqueues `GenerateReportJob`

### View the Dashboard
- Loads all active organizations
- For each org: counts schools, classrooms, students, sessions in Ruby (N+1 hotspot)
- Shows recent 20 sessions without eager loading

### Engineering Dashboard
- `/engineering` shows 7 phases with epics, stories, tasks
- Progress bars computed from task completion counts
- Task status can be updated inline via form (PATCH to `/engineering/tasks/:id`)

## Session Status State Machine

```
draft → in_progress → finalized
                    → cancelled
```

Transitions are manual (no state machine gem — just enum + guards in `finalize!`).

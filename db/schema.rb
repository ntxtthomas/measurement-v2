# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_01_15_000017) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "classrooms", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "teacher_id"
    t.string "name", null: false
    t.string "grade_level"
    t.string "subject"
    t.datetime "last_observed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_classrooms_on_school_id"
    t.index ["teacher_id"], name: "index_classrooms_on_teacher_id"
  end

  create_table "epics", force: :cascade do |t|
    t.bigint "phase_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id", "position"], name: "index_epics_on_phase_id_and_position"
    t.index ["phase_id"], name: "index_epics_on_phase_id"
  end

  create_table "observation_dimensions", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.string "category", null: false
    t.integer "min_score", default: 1, null: false
    t.integer "max_score", default: 7, null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_observation_dimensions_on_active"
    t.index ["category"], name: "index_observation_dimensions_on_category"
    t.index ["code"], name: "index_observation_dimensions_on_code", unique: true
  end

  create_table "observation_note_students", force: :cascade do |t|
    t.bigint "observation_note_id", null: false
    t.bigint "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observation_note_id", "student_id"], name: "idx_note_students_unique", unique: true
    t.index ["observation_note_id"], name: "index_observation_note_students_on_observation_note_id"
    t.index ["student_id"], name: "index_observation_note_students_on_student_id"
  end

  create_table "observation_notes", force: :cascade do |t|
    t.bigint "observation_session_id", null: false
    t.bigint "observer_id", null: false
    t.text "content", null: false
    t.integer "seconds_into_session"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observation_session_id"], name: "index_observation_notes_on_observation_session_id"
    t.index ["observer_id"], name: "index_observation_notes_on_observer_id"
  end

  create_table "observation_scores", force: :cascade do |t|
    t.bigint "observation_session_id", null: false
    t.bigint "observation_dimension_id", null: false
    t.integer "score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observation_dimension_id"], name: "index_observation_scores_on_observation_dimension_id"
    t.index ["observation_session_id"], name: "index_observation_scores_on_observation_session_id"
  end

  create_table "observation_sessions", force: :cascade do |t|
    t.bigint "observer_id", null: false
    t.bigint "classroom_id", null: false
    t.bigint "teacher_id", null: false
    t.integer "status", default: 0, null: false
    t.date "observed_on", null: false
    t.datetime "finalized_at"
    t.integer "finalized_by_id"
    t.integer "notes_count_cache", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_observation_sessions_on_classroom_id"
    t.index ["observer_id"], name: "index_observation_sessions_on_observer_id"
    t.index ["teacher_id"], name: "index_observation_sessions_on_teacher_id"
  end

  create_table "observers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "certification_level", default: "standard"
    t.date "certified_on"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_observers_on_active"
    t.index ["organization_id"], name: "index_observers_on_organization_id"
    t.index ["user_id"], name: "index_observers_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "contact_email"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["status"], name: "index_organizations_on_status"
  end

  create_table "phases", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.string "color", default: "#6366f1"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_phases_on_position"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "observation_session_id", null: false
    t.integer "generated_by", null: false
    t.integer "status", default: 0, null: false
    t.text "content"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observation_session_id"], name: "index_reports_on_observation_session_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "schools", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_schools_on_organization_id"
    t.index ["status"], name: "index_schools_on_status"
  end

  create_table "stories", force: :cascade do |t|
    t.bigint "epic_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["epic_id", "position"], name: "index_stories_on_epic_id_and_position"
    t.index ["epic_id"], name: "index_stories_on_epic_id"
  end

  create_table "students", force: :cascade do |t|
    t.bigint "classroom_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "date_of_birth"
    t.string "student_id_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_students_on_classroom_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["story_id", "position"], name: "index_tasks_on_story_id_and_position"
    t.index ["story_id"], name: "index_tasks_on_story_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "grade_levels"
    t.integer "total_sessions", default: 0
    t.decimal "average_score_cache", precision: 4, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_teachers_on_school_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role", default: "observer", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "classrooms", "schools"
  add_foreign_key "classrooms", "teachers"
  add_foreign_key "epics", "phases"
  add_foreign_key "observation_note_students", "observation_notes"
  add_foreign_key "observation_note_students", "students"
  add_foreign_key "observation_notes", "observation_sessions"
  add_foreign_key "observation_notes", "observers"
  add_foreign_key "observation_scores", "observation_dimensions"
  add_foreign_key "observation_scores", "observation_sessions"
  add_foreign_key "observation_sessions", "classrooms"
  add_foreign_key "observation_sessions", "observers"
  add_foreign_key "observation_sessions", "teachers"
  add_foreign_key "observers", "organizations"
  add_foreign_key "observers", "users"
  add_foreign_key "reports", "observation_sessions"
  add_foreign_key "schools", "organizations"
  add_foreign_key "stories", "epics"
  add_foreign_key "students", "classrooms"
  add_foreign_key "tasks", "stories"
  add_foreign_key "teachers", "schools"
end

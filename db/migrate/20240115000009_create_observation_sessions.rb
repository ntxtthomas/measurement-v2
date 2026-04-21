class CreateObservationSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :observation_sessions do |t|
      t.references :observer,  null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.references :teacher,   null: false, foreign_key: true
      # INTENTIONAL DENORMALIZATION: teacher_id is redundant (derivable from classroom)
      # but stored directly. Creates potential inconsistency + maintenance burden.

      t.integer  :status,             null: false, default: 0
      t.date     :observed_on,        null: false
      t.datetime :finalized_at
      t.integer  :finalized_by_id
      t.integer  :notes_count_cache,  default: 0  # manually maintained, gets stale

      t.timestamps
    end

    # INTENTIONAL MISSING INDEXES:
    # - No index on :status  (common filter; full table scan at scale)
    # - No index on :observed_on  (date range queries; will hurt in reports)
    # - No composite (observer_id, status) even though "my open sessions" queries run often
    #
    # Adding these is a canonical early performance task.
    # Note: t.references above auto-creates indexes on observer_id, classroom_id, teacher_id
  end
end

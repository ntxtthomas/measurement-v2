class CreateObservationScores < ActiveRecord::Migration[7.1]
  def change
    create_table :observation_scores do |t|
      t.references :observation_session,   null: false, foreign_key: true
      t.references :observation_dimension, null: false, foreign_key: true
      t.integer    :score, null: false

      t.timestamps
    end

    # INTENTIONAL MISSING INDEX:
    # No unique index on (observation_session_id, observation_dimension_id).
    # This allows duplicate scores per dimension on the same session — a data integrity hole.
    # Also means duplicate-check logic ends up in Ruby instead of the DB.
    #
    # HOT SPOT: This join is done in every report and every dashboard rollup.
    # Adding add_index :observation_scores, [:observation_session_id, :observation_dimension_id], unique: true
    # is a named performance + integrity task.
    # Note: t.references above auto-creates indexes on observation_session_id and observation_dimension_id
  end
end

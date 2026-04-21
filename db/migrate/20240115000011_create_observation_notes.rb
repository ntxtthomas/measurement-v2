class CreateObservationNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :observation_notes do |t|
      t.references :observation_session, null: false, foreign_key: true
      t.references :observer,            null: false, foreign_key: true
      # INTENTIONAL REDUNDANCY: observer_id is on the session; storing here creates
      # a denormalization that must be kept in sync. Candidate for removal.
      t.text    :content, null: false
      t.integer :seconds_into_session  # wall-clock offset, not always populated

      t.timestamps
    end

    # Note: t.references above auto-creates index on observation_session_id and observer_id
    # INTENTIONAL: observer_id index exists; no composite (session+observer) index
  end
end

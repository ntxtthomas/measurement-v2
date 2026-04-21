class CreateObservationNoteStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :observation_note_students do |t|
      t.references :observation_note, null: false, foreign_key: true
      t.references :student,          null: false, foreign_key: true

      t.timestamps
    end

    add_index :observation_note_students, [:observation_note_id, :student_id], unique: true,
              name: "idx_note_students_unique"
    # INTENTIONAL: No index on student_id alone — "all notes mentioning student X" will scan
  end
end

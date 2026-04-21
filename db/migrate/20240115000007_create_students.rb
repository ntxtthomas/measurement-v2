class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.references :classroom, null: false, foreign_key: true
      t.string :first_name,  null: false
      t.string :last_name,   null: false
      t.date   :date_of_birth
      t.string :student_id_number  # external identifier, no uniqueness constraint — a real data quality issue

      t.timestamps
    end

    # INTENTIONAL: No index on student_id_number even though lookups by this field
    # will happen in reporting. Candidate for a later migration + unique constraint.
  end
end

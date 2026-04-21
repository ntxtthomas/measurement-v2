class CreateTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :teachers do |t|
      t.references :school, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :email
      t.string :grade_levels  # comma-separated, intentional design laziness
      t.integer :total_sessions,       default: 0
      t.decimal :average_score_cache,  precision: 4, scale: 2  # denormalized cache — gets stale

      t.timestamps
    end

    # INTENTIONAL: No index on last_name even though search-by-name is common

    # Add FK from classrooms to teachers now that teachers table exists
    add_foreign_key :classrooms, :teachers
  end
end

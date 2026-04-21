class CreateClassrooms < ActiveRecord::Migration[7.1]
  def change
    create_table :classrooms do |t|
      t.references :school,  null: false, foreign_key: true
      t.bigint     :teacher_id  # FK added after teachers table exists (see migration 20240115000006)
      t.string :name, null: false
      t.string :grade_level
      t.string :subject
      t.datetime :last_observed_at

      t.timestamps
    end

    add_index :classrooms, :teacher_id

    # INTENTIONAL MISSING INDEX: no index on grade_level or subject even though
    # the dashboard filters on these frequently.
    # HOT SPOT: classroom queries without grade_level index will scan.
  end
end

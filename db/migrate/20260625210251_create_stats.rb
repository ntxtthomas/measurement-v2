class CreateStats < ActiveRecord::Migration[7.1]
  def change
    create_table :stats do |t|
      t.string :key, null: false
      t.integer :total_sessions, null: false, default: 0
      t.integer :total_students, null: false, default: 0
      t.integer :total_finalized, null: false, default: 0
      t.datetime :refreshed_at, null: false

      t.timestamps
    end
    add_index :stats, :key, unique: true
  end
end

class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :story, null: false, foreign_key: true
      t.string  :name,        null: false
      t.text    :description
      t.integer :status,      null: false, default: 0  # 0=not_started, 1=in_progress, 2=blocked, 3=done
      t.integer :position,    null: false, default: 0
      t.text    :notes        # engineer's working notes, freeform

      t.timestamps
    end

    add_index :tasks, [:story_id, :position]
    add_index :tasks, :status
  end
end

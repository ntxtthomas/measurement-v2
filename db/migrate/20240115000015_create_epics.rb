class CreateEpics < ActiveRecord::Migration[7.1]
  def change
    create_table :epics do |t|
      t.references :phase, null: false, foreign_key: true
      t.string  :name,        null: false
      t.text    :description
      t.integer :position,    null: false, default: 0

      t.timestamps
    end

    add_index :epics, [:phase_id, :position]
  end
end

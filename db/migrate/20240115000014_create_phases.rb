class CreatePhases < ActiveRecord::Migration[7.1]
  def change
    create_table :phases do |t|
      t.string  :name,        null: false
      t.text    :description
      t.integer :position,    null: false, default: 0
      t.string  :color,       default: "#6366f1"  # used in progress bars

      t.timestamps
    end

    add_index :phases, :position
  end
end

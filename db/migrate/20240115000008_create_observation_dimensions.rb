class CreateObservationDimensions < ActiveRecord::Migration[7.1]
  def change
    create_table :observation_dimensions do |t|
      t.string  :name,        null: false
      t.string  :code,        null: false
      t.text    :description
      t.string  :category,    null: false  # e.g. "Emotional Support", "Instructional Support"
      t.integer :min_score,   null: false, default: 1
      t.integer :max_score,   null: false, default: 7
      t.integer :position,    null: false, default: 0
      t.boolean :active,      null: false, default: true

      t.timestamps
    end

    add_index :observation_dimensions, :code,     unique: true
    add_index :observation_dimensions, :active
    add_index :observation_dimensions, :category
  end
end

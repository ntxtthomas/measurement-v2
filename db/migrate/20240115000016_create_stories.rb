class CreateStories < ActiveRecord::Migration[7.1]
  def change
    create_table :stories do |t|
      t.references :epic, null: false, foreign_key: true
      t.string  :name,        null: false
      t.text    :description
      t.integer :position,    null: false, default: 0

      t.timestamps
    end

    add_index :stories, [:epic_id, :position]
  end
end

class CreateObservers < ActiveRecord::Migration[7.1]
  def change
    create_table :observers do |t|
      t.references :user,         null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :certification_level, default: "standard"
      t.date   :certified_on
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :observers, :active
    # INTENTIONAL: No composite (organization_id, active) index — common filter path
  end
end

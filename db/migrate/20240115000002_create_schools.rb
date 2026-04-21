class CreateSchools < ActiveRecord::Migration[7.1]
  def change
    create_table :schools do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :state
      t.string :status, default: "active", null: false

      t.timestamps
    end

    # INTENTIONAL: index on organization_id added (foreign key adds it in PG, but
    # notice no composite index on (organization_id, status) which would help common queries)
    add_index :schools, :status
  end
end

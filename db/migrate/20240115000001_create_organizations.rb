class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :contact_email
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :status
  end
end

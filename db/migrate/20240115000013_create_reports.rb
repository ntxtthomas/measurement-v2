class CreateReports < ActiveRecord::Migration[7.1]
  def change
    create_table :reports do |t|
      t.references :observation_session, null: false, foreign_key: true
      t.integer :generated_by, null: false  # user_id, intentionally not a FK
      t.integer :status, null: false, default: 0
      t.text    :content       # raw JSON blob — no structure enforcement
      t.text    :error_message

      t.timestamps
    end

    # Note: t.references above auto-creates index on observation_session_id
    add_index :reports, :status
    # INTENTIONAL: Multiple reports per session are possible (no unique constraint).
    # This is the non-idempotent job problem — retries create duplicate rows.
  end
end

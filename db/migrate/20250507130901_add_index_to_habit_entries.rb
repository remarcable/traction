class AddIndexToHabitEntries < ActiveRecord::Migration[8.0]
  def change
    add_index :habit_entries, [ :habit_id, :date ], unique: true
  end
end

class AddValueToHabitEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :habit_entries, :value, :string, null: false, default: "PENDING"
  end
end

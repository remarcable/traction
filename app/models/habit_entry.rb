class HabitEntry < ApplicationRecord
  belongs_to :habit
  validates :date, presence: true
  add_index :habit_entries, [:habit_id, :date], unique: true
end

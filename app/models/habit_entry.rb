class HabitEntry < ApplicationRecord
  belongs_to :habit
  validates :date, presence: true
  validates :value, presence: true

  add_index :habit_entries, [:habit_id, :date], unique: true

  enum value: {
    pending: 'PENDING',
    completed: 'COMPLETED',
    failed: 'FAILED',
    skipped: 'SKIPPED'
  }
end

class HabitEntry < ApplicationRecord
  belongs_to :habit
  validates :date, presence: true
  validates :status, presence: true

  enum :status, {
    pending: "PENDING",
    completed: "COMPLETED",
    failed: "FAILED",
    skipped: "SKIPPED"
  }
end

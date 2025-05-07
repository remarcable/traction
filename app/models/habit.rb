class Habit < ApplicationRecord
  belongs_to :user
  has_many :habit_entries, dependent: :destroy
  validates :name, presence: true

  def entries_for_current_week
    start_of_week = Date.current.beginning_of_week
    end_of_week = Date.current.end_of_week

    existing_entries = habit_entries.where(date: start_of_week..end_of_week)
    entries_by_date = existing_entries.index_by(&:date)

    (start_of_week..end_of_week).map do |date|
      entries_by_date[date] || HabitEntry.new(date: date, habit: self)
    end
  end
end

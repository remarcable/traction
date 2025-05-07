json.extract! habit_entry, :id, :created_at, :updated_at
json.url habit_habit_entry_url(@habit, habit_entry, format: :json)

class CreateHabitEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :habit_entries do |t|
      t.belongs_to :habit, null: false, foreign_key: true
      t.date :date

      t.timestamps
    end
  end
end

class ChangeForeignKeysToBigInt < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :habit_entries, :habits
    change_column :habit_entries, :habit_id, :bigint, null: false
    add_foreign_key :habit_entries, :habits

    remove_foreign_key :habits, :users
    change_column :habits, :user_id, :bigint, null: false
    add_foreign_key :habits, :users

    remove_foreign_key :sessions, :users
    change_column :sessions, :user_id, :bigint, null: false
    add_foreign_key :sessions, :users
  end
end

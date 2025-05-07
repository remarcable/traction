require "application_system_test_case"

class HabitEntriesTest < ApplicationSystemTestCase
  setup do
    @habit_entry = habit_entries(:one)
  end

  test "visiting the index" do
    visit habit_entries_url
    assert_selector "h1", text: "Habit entries"
  end

  test "should create habit entry" do
    visit habit_entries_url
    click_on "New habit entry"

    click_on "Create Habit entry"

    assert_text "Habit entry was successfully created"
    click_on "Back"
  end

  test "should update Habit entry" do
    visit habit_entry_url(@habit_entry)
    click_on "Edit this habit entry", match: :first

    click_on "Update Habit entry"

    assert_text "Habit entry was successfully updated"
    click_on "Back"
  end

  test "should destroy Habit entry" do
    visit habit_entry_url(@habit_entry)
    click_on "Remove habit entry", match: :first

    assert_text "Habit entry was successfully destroyed"
  end
end

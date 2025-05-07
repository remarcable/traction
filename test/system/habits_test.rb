require "application_system_test_case"

class HabitsTest < ApplicationSystemTestCase
  setup do
    @habit = habits(:one)
  end

  test "visiting the index" do
    visit habits_url
    assert_selector "h1", text: "Habits"
  end

  test "should create habit" do
    visit habits_url
    click_on "New habit"

    click_on "Create Habit"

    assert_text "Habit was successfully created"
    click_on "Back"
  end

  test "should update Habit" do
    visit habit_url(@habit)
    click_on "Edit this habit", match: :first

    click_on "Update Habit"

    assert_text "Habit was successfully updated"
    click_on "Back"
  end

  test "should destroy Habit" do
    visit habit_url(@habit)
    click_on "Remove habit", match: :first

    assert_text "Habit was successfully destroyed"
  end
end

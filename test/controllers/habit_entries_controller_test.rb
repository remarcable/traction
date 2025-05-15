require "test_helper"

class HabitEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "test@example.com", password: "secret")
    post "/session", params: { email_address: @user.email_address, password: "secret" }

    @habit = Habit.create!(name: "Test Habit", user: @user)
    @habit_entry = HabitEntry.create!(
      habit: @habit,
      status: "pending",
      date: Date.today
    )
  end

  def with_referer
    { headers: { "HTTP_REFERER" => habits_url } }
  end

  test "should cycle through all possible statuses" do
    statuses = HabitEntry.statuses.keys
    statuses.each do |status|
      @habit_entry.update!(status: status)
      patch cycle_status_habit_habit_entry_url(@habit, @habit_entry), **with_referer
      assert_response :redirect
      @habit_entry.reload
      expected_status = statuses[(statuses.index(status) + 1) % statuses.length]
      assert_equal expected_status, @habit_entry.status
    end
  end

  test "should create new habit entry with different dates" do
    dates = [ Date.tomorrow, Date.tomorrow + 1.day ]
    dates.each do |date|
      assert_difference("HabitEntry.count") do
        post create_and_cycle_habit_habit_entries_url(@habit),
             params: { date: date },
             **with_referer
      end
      assert_response :redirect
      new_entry = HabitEntry.last
      assert_equal date, new_entry.date
      assert_equal "completed", new_entry.status
    end
  end

  test "should not create duplicate entries for same date" do
    date = Date.tomorrow
    assert_difference("HabitEntry.count") do
      post create_and_cycle_habit_habit_entries_url(@habit),
           params: { date: date },
           **with_referer
    end

    assert_no_difference("HabitEntry.count") do
      post create_and_cycle_habit_habit_entries_url(@habit),
           params: { date: date },
           **with_referer
    end
    assert_redirected_to request.referer
    assert_equal "Entry already exists for this date", flash[:alert]
  end

  test "should handle failed habit entry creation" do
    assert_no_difference("HabitEntry.count") do
      post create_and_cycle_habit_habit_entries_url(@habit),
           params: { date: nil },
           **with_referer
    end

    assert_redirected_to request.referer
    assert_equal "Could not create entry", flash[:alert]
  end

  test "should not allow access to other user's habit entries" do
    other_user = User.create!(email_address: "other@example.com", password: "secret")
    other_habit = Habit.create!(name: "Other Habit", user: other_user)
    other_entry = HabitEntry.create!(
      habit: other_habit,
      status: "pending",
      date: Date.today
    )

    patch cycle_status_habit_habit_entry_url(other_habit, other_entry), **with_referer
    assert_response :not_found
  end

  test "should handle invalid habit ID" do
    patch cycle_status_habit_habit_entry_url(0, @habit_entry), **with_referer
    assert_response :not_found
  end

  test "should handle invalid entry ID" do
    patch cycle_status_habit_habit_entry_url(@habit, 0), **with_referer
    assert_response :not_found
  end
end

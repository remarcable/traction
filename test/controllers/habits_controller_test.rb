require "test_helper"

class HabitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "test@example.com", password: "secret")
    post "/session", params: { email_address: @user.email_address, password: "secret" }
    
    @habit = Habit.create!(name: "Test Habit", user: @user)
  end

  test "should get index" do
    get habits_url
    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
  end

  test "should get new" do
    get new_habit_url
    assert_response :success
  end

  test "should create habit with valid name" do
    assert_difference("Habit.count") do
      post habits_url, params: { habit: { name: "New Habit" } }
    end

    assert_redirected_to habit_url(Habit.last)
    assert_equal "Habit was successfully created.", flash[:notice]
    assert_equal "New Habit", Habit.last.name
  end

  test "should not create habit with empty name" do
    assert_no_difference("Habit.count") do
      post habits_url, params: { habit: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create habit with nil name" do
    assert_no_difference("Habit.count") do
      post habits_url, params: { habit: { name: nil } }
    end

    assert_response :unprocessable_entity
  end

  test "should show habit" do
    get habit_url(@habit)
    assert_response :success
    assert_includes @response.body, @habit.name
  end

  test "should get edit" do
    get edit_habit_url(@habit)
    assert_response :success
    assert_includes @response.body, @habit.name
  end

  test "should update habit name" do
    updated_name = "Updated Habit"
    patch habit_url(@habit), params: { habit: { name: updated_name } }
    assert_redirected_to habit_url(@habit)
    assert_equal "Habit was successfully updated.", flash[:notice]
    @habit.reload
    assert_equal updated_name, @habit.name
  end

  test "should not update habit with empty name" do
    original_name = @habit.name
    patch habit_url(@habit), params: { habit: { name: "" } }
    assert_response :unprocessable_entity
    @habit.reload
    assert_equal original_name, @habit.name
  end

  test "should destroy habit" do
    assert_difference("Habit.count", -1) do
      delete habit_url(@habit)
    end

    assert_redirected_to habits_url
    assert_equal "Habit was successfully destroyed.", flash[:notice]
  end

  test "should not allow access to other user's habits" do
    other_user = User.create!(email_address: "other@example.com", password: "secret")
    other_habit = Habit.create!(name: "Other Habit", user: other_user)

    get habit_url(other_habit)
    assert_response :not_found

    patch habit_url(other_habit), params: { habit: { name: "Hacked Habit" } }
    assert_response :not_found

    delete habit_url(other_habit)
    assert_response :not_found
  end

  test "should handle special characters in habit names" do
    special_name = "Habit!@#$%^&*()_+"
    patch habit_url(@habit), params: { habit: { name: special_name } }
    assert_redirected_to habit_url(@habit)
    @habit.reload
    assert_equal special_name, @habit.name
  end
end

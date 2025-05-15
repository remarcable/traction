require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user with valid data" do
    assert_difference("User.count") do
      post users_url, params: { user: { email_address: "new@example.com", password: "secret", password_confirmation: "secret" } }
    end

    assert_redirected_to root_url
    assert_equal "Welcome! Your account has been created.", flash[:notice]
  end

  test "should not create user with invalid email" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { email_address: "invalid", password: "secret", password_confirmation: "secret" } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create user with mismatched passwords" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { email_address: "new@example.com", password: "secret", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create user with existing email" do
    User.create!(email_address: "existing@example.com", password: "secret")

    assert_no_difference("User.count") do
      post users_url, params: { user: { email_address: "existing@example.com", password: "secret", password_confirmation: "secret" } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create user with empty password" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { email_address: "new@example.com", password: "", password_confirmation: "" } }
    end

    assert_response :unprocessable_entity
  end
end

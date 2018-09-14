require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test "login with valid information followed by logout" do  
    #test logging in
    get login_path
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    assert_redirected_to root_path

    #test flash is not empty, and does not continue to next request
    assert_not flash.empty?
    get root_path

    assert is_logged_in?
    assert_template root_path
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path

    #test logging out
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
  end

end
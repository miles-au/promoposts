require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @other = users(:archer)
  end

  test "micropost interface (admin)" do
    log_in_as(@user)
    assert @user.admin
    get root_path
    #assert pagination is working
    #assert_select 'div.pagination'
    #assert_select 'input[type=file]'
    # Invalid submission
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: ""}}
    end
    assert_select 'div#error_explanation'
    # Valid submission
    content = "This micropost really ties the room together"
    picture = fixture_file_upload('test/fixtures/rails.png', 'image/png')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost:
                                      { content: content,
                                        picture: picture } }
    end
    m = assigns(:micropost)
    assert m.picture?
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    # Delete post
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1, per_page: 9).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end

    # Visit different user as admin
    get user_path(users(:archer))
    assert_select 'a', text: 'delete'

  end

  test "micropost interface as regular user" do
  	delete logout_path
  	log_in_as(users(:lana))
  	# Visit different user (no delete links)
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end

  test "global feed and user feed appear correctly if logged in/not logged in" do
    #logged in
    log_in_as(@user)
    assert is_logged_in?
    follow_redirect!
    assert_select "h5", "Your Feed"
    assert_select "h5", "Global Feed"
    assert_select "h5", "Vendor Feed"

    #post content to test appearance on other feed
    content = "Should not show up on user feed"
    post microposts_path, params: { micropost: { content: content } }

    #logged out
    delete logout_path
    follow_redirect!
    assert_select "a[href='user_feed']", false
    assert_select "h5", "Global Feed"

    #log back in as other user
    assert_match content, response.body
    log_in_as(@other)
    follow_redirect!
    relationship = @other.active_relationships.find_by(followed_id: @user.id)
    delete relationship_path(relationship)
    assert_not @other.active_relationships.find_by(followed_id: @user.id)
    get root_path
    assert_no_match content, response.body

  end

end
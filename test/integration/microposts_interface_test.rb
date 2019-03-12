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
      before_count = Event.count
      post microposts_path, params: { micropost:
                                      { content: content,
                                        picture: picture } }
      after_count = Event.count
      assert_equal(before_count + 1, after_count)
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

    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: ""}}
    end

  	log_in_as(users(:lana))
  	# Visit different user (no delete links)
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end

  test "micropost post 6 times in succession" do
    ENV["THROTTLE_DURING_TEST"] = "true"

    log_in_as(users(:lana))

    assert_difference 'Micropost.count', 5 do
        5.times do
          content = Faker::Lorem.sentence(5)
          post microposts_path, params: { micropost: { content: content}}
        end
    end

    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "this is one too many"}}
    end

    ENV["THROTTLE_DURING_TEST"] = "false"
    Rails.cache.clear
  end

  test "global feed and user feed appear correctly if logged in/not logged in" do
    #logged in
    log_in_as(@user)
    assert is_logged_in?
    follow_redirect!
    assert_select "h5", "Your Feed"
    assert_select "h5", "Global Feed"
    assert_select "h5", "Vendor Feed"
    assert_select "h5", "Questions"
    assert_select "h5", "Careers"

    #post content to test appearance on other feed
    content = "Should not show up on user feed"
    post microposts_path, params: { micropost: { content: content } }

    #logged out
    delete logout_path
    follow_redirect!
    assert_select "h5", text: "Your Feed", count: 0
    assert_select "h5", text: "Global Feed", count: 1

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

  test "vendor feed has vendor posts only" do
    log_in_as(users(:imadistributor))
    dist_content = "distributor post"
    post microposts_path, params: { micropost: { content: dist_content } }
    get root_path(feed: 'vendor')
    assert_no_match dist_content, response.body
    delete logout_path

    log_in_as(users(:imavendor))
    vend_content = "vendor post"
    post microposts_path, params: { micropost: { content: vend_content } }
    get root_path(feed: 'vendor')
  end

  test 'questions feed has questions posts only' do
    log_in_as(@user)
    non_question = "not a question"
    post microposts_path, params: { micropost: { content: non_question } }
    get root_path
    assert_match non_question, response.body
    get root_path(feed: 'questions')
    assert_no_match non_question, response.body

    question = "question!"
    post microposts_path, params: { micropost: { content: question, category: 'question' } }
    get root_path
    assert_match question, response.body
    get root_path(feed: 'questions')
    assert_match question, response.body
  end

  test 'mark top comment on questions' do
    #log in as user and post question
    log_in_as(@user)
    micropost = microposts(:question)
    delete logout_path
    reply = "reply!"
    assert_no_difference 'Comment.count' do
      post comments_path, params: { comment: { micropost_id: micropost.id, message: reply, user_id: @user.id} }
    end

    #log in as other user and post reply
    log_in_as(@other)
    assert_difference 'Comment.count' do
      post comments_path, params: { comment: { micropost_id: micropost.id, message: reply, user_id: @other.id } }
    end
    get micropost_path(micropost)
    assert_match reply, response.body
    assert_select "a", text: "mark as top comment", count: 0
    delete logout_path

    #log in as user and mark top comment
    log_in_as(@user)
    get micropost_path(micropost)
    assert_select "a", text: "mark as top comment", count: 1
    comment = Comment.last
    get mark_top_comment_path(comment_id: comment.id,micropost_id: micropost.id)
    get micropost_path(micropost)
    assert_select "span.top-comment", count: 1
    assert_select "div#comment-content-#{comment.id} span.top-comment"

  end

  test 'careers feed has career posts only' do
    log_in_as(@user)
    non_career = "not a career"
    post microposts_path, params: { micropost: { content: non_career } }
    get root_path
    assert_match non_career, response.body
    get root_path(feed: 'careers')
    assert_no_match non_career, response.body

    career = "career!"
    post microposts_path, params: { micropost: { content: career, category: 'careers' } }
    get root_path
    assert_match career, response.body
    get root_path(feed: 'careers')
    assert_match career, response.body
  end

end
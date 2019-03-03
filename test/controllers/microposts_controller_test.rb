require 'test_helper'

class MicropostsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @micropost = microposts(:orange)
    @admin = users(:michael)
    @user = users(:archer)
  end

  test "should redirect create when not logged in" do
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "Lorem ipsum" } }
    end
    assert_redirected_to social_login_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference 'Micropost.count' do
      delete micropost_path(@micropost)
    end
    assert_redirected_to social_login_url
  end

  test "should redirect destroy for wrong micropost" do
    log_in_as(@user)
    assert_not @user.admin
    micropost = microposts(:tone)
    assert_no_difference 'Micropost.count' do
      delete micropost_path(micropost)
    end
    assert_redirected_to root_url
  end

  test "admin can destroy micropost" do
    log_in_as(@admin)
    assert @admin.admin
    micropost = microposts(:tone)

    before_delete = Micropost.count
    delete micropost_path(micropost)
    after_delete = Micropost.count

    assert_not_equal(before_delete, after_delete)
    assert_redirected_to root_url
  end
  
end
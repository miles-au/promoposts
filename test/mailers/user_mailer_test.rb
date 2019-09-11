require 'test_helper'

class UserMailerTest < ActionMailer::TestCase

  def setup
    @user = users(:michael)
    @micropost = microposts(:orange)
    @message = "Display a comment"
    @category = "post"
    @commenter = users(:archer)
  end

end

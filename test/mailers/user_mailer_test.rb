require 'test_helper'

class UserMailerTest < ActionMailer::TestCase

  def setup
    @user = users(:michael)
    @micropost = microposts(:orange)
    @message = "Display a comment"
    @category = "post"
    @commenter = users(:archer)
  end

  test "comment" do
    mail = UserMailer.comment(@user, @micropost, @message, @category, @commenter)
    assert_equal "Promo Posts - Somebody commented on your #{@category}!", mail.subject
    assert_equal [users(:michael).email], mail.to
    assert_equal ['noreply@promoposts.net'], mail.from
  end

end

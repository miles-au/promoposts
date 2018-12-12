# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/account_activation
  def account_activation
    user = User.first
    user.activation_token = User.new_token
    UserMailer.account_activation(user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/password_reset
  def password_reset
    user = User.first
    user.reset_token = User.new_token
    UserMailer.password_reset(user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/comment
  def comment
    user = User.first
    micropost = Micropost.first
    message = 'test comment'
    category = "post"
    commenter = User.second
    UserMailer.comment(user, micropost, message, category, commenter)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/contacted
  def contacted
    email = "testemail@promoposts.net"
    subject = "Test Email Subject"
    message = "Testing email message"
    UserMailer.contacted(email, subject, message)
  end

end
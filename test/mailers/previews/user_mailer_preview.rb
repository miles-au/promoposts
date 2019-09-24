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
  # http://localhost:3000/rails/mailers/user_mailer/contacted
  def contacted
    email = "testemail@promoposts.net"
    subject = "Test Email Subject"
    message = "Testing email message"
    UserMailer.contacted(email, subject, message)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/send_lead
  def send_lead
    email = "lead_email@lead_company.com"
    campaign = Campaign.first
    message = "Hi, I'm interested in your promotional products."
    lead_name = "Test Lead"
    user = User.first
    UserMailer.send_lead(email, campaign, message, lead_name, user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/verify_email
  def verify_email
    user = User.first
    user.activation_token = "1234"
    email = "testemail@promoposts.net"
    UserMailer.verify_email(user, email)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/followed_email
  def followed_email
    recipient = User.first
    follower = User.second
    UserMailer.followed_email(recipient, follower)
  end

end
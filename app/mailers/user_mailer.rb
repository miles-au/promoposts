class UserMailer < ApplicationMailer


  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Promo Posts - Account activation"
  end

  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Promo Posts - Password reset"
  end

  def comment(user, micropost, message, category, commenter)
  	@user = user
  	@category = category
  	@micropost = micropost
  	@message = message
  	@commenter = commenter
  	mail to: user.email, subject: "Promo Posts - Somebody commented on your #{category}!"
  end

  def subscribe(user)
  end

  def contacted(email, subject, message)
    @message = message
    @email = email
    mail to: 'contact@promoposts.net', subject: subject
  end

  def verify_email(user, email)
    @user = user
    @email = email
    mail to: email, subject: "Promo Posts - Email Verification"
  end

  def followed_email(recipient, follower)
    @user = recipient
    @follower = follower
    mail to: recipient.email, subject: "Promo Posts - You have a new follower!"
  end

  def community_question_notification(recipient, micropost)
    @user = recipient
    @micropost = micropost
    mail to: @user.email, subject: "Promo Posts - Can you answer this question?"
  end

end
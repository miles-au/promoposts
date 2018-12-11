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

end
class UserMailer < ApplicationMailer

  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Promo Posts - Account activation"
  end

  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Promo Posts - Password reset"
  end
end
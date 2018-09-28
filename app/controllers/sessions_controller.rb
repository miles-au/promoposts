class SessionsController < ApplicationController

  def new
  end

  def create
    
    raise request.env["omniauth.auth"].to_yaml

    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      if user.activated?
      	flash[:success] = "Welcome to Promo Posts, #{user.name}."
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or root_url
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link. "
        message += "#{view_context.link_to('Click here to resend link', sessions_resend_activation_path(email: user.email))}".html_safe
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  def resend_activation
  	@user = User.find_by_email(params[:email])
    if @user
      @user.resend_activation_email
      flash[:success] = "Activation email resent! You should receive your link shortly."
      redirect_to root_url
    else
      flash[:danger] = 'Email is not asociated with any account, please sign up first.'
      redirect_to root_url
    end
  end

end

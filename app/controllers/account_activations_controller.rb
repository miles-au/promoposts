class AccountActivationsController < ApplicationController
  
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      User.verify_email(user.id)
      log_in user
      flash[:success] = "Account activated!"
      redirect_to root_url      
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end

  def update_email
    puts "PARAMS: #{params}"
    user = User.find(params[:user_id])
    if user && user.authenticated?(:activation, params[:id])
      user.activate
      user.email = params[:email]
      user.save!
      User.verify_email(user.id)
      log_in user
      flash[:success] = "Email verified!"
      redirect_to root_url      
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end

end

class OauthController < ApplicationController

  def failure
    error_message = request.env["omniauth.error"].message rescue nil
  	intent = params['intent']

    if error_message.include?("You have exceeded your rate limit. Try again later.")
      flash[:danger] = "We appreciate the enthusiasm. Unfortunately, you are making too many requests."
      rredirect_back(fallback_location: root_path)
  	else
  		flash[:danger] = "Promo Posts is experiencing some technical difficulties, we apologize for the inconvenience."
  		redirect_back(fallback_location: root_path)
  	end
  end

  def callback
    par = request.env['omniauth.params']
    auth = request.env['omniauth.auth']
    # connect social accounts
    if logged_in?

      # update stored tokens
      connect_accounts_resp = current_user.connect_accounts(auth)
      if !connect_accounts_resp
        flash[:danger] = "There was an issue connecting your #{auth['provider']} account."

      # create accounts
      elsif Account.send("create_#{auth['provider']}_accounts", current_user, auth)
        flash[:success] = "Your #{auth['provider']} account has been connected."

      else
        flash[:danger] = "There was an issue connecting your #{auth['provider']} account."
      end
      redirect_back_or accounts_edit_path
    else
      flash[:danger] = "Please sign in first."
      redirect_to login_path
    end
  end

end
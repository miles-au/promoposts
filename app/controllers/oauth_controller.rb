class OauthController < ApplicationController

  def failure
    error_message = request.env["omniauth.error"].message rescue nil
  	intent = params['intent']

    if error_message.include?("You have exceeded your rate limit. Try again later.")
      flash[:danger] = "We appreciate the enthusiasm. Unfortunately, you are making too many requests."
      redirect_to root_url
  	elsif intent
  		flash[:danger] = "There was an error while authenticating your account, we apologize for the inconvenience."
  		if intent == 'connect'
    		redirect_to '/accounts/edit'
  		elsif intent == 'sign_in'
  			redirect_to '/social_login'
  		end
  	else
  		flash[:danger] = "Promo Posts is experiencing some technical difficulties, we apologize for the inconvenience."
  		redirect_back(fallback_location: root_path)
  	end
  end

  def callback
  	
  end

end
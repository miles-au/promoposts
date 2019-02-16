class OauthController < ApplicationController

  def failure
  	intent = params['intent']

  	if intent
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
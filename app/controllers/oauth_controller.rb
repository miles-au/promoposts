class OauthController < ApplicationController

  def failure
    flash[:alert] = "There was an error while trying to authenticate your account."
    redirect_to login_path
  end

  def callback
  	
  end

end
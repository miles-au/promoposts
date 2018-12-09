class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include SessionsHelper

  private

    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to social_login_url
      end
    end

    # Confirms a logged-in user.
    def logged_out_user
      unless !logged_in?
        store_location
        flash[:success] = "You are currently logged in."
        redirect_to root_path
      end
    end
  
end
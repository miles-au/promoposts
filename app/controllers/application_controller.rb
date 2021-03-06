class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include SessionsHelper

  private

    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_path
      end
    end

    # Confirms a logged-out user.
    def logged_out_user
      unless !logged_in?
        store_location
        flash[:success] = "Welcome to Promo Posts, #{current_user.name}"
        redirect_to root_path
      end
    end
    
end
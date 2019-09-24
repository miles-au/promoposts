class LandingPageController < ApplicationController
	before_action :logged_in_user

	def show
		@landing_page = LandingPage.find(params[:id])
		@contact = Contact.new(:email => "", :message => "")
	end

	def destroy
		landing_page = LandingPage.find(params[:id])
		campaign = landing_page.campaign
		if landing_page.campaign.user == current_user || current_user.admin
			landing_page.destroy
    		flash[:success] = "Landing page deleted"
		else
			flash[:danger] = "You are not authorized to delete this landing page."
		end
		redirect_to campaign
	end
end
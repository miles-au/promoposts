class LandingPageController < ApplicationController
	def preview
		@landing_page = LandingPage.find(params[:id])
		@contact = Contact.new(:email => "", :message => "")
	end
end
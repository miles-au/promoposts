class PromodigiController < ApplicationController
	def home
		if params[:destination] == "landingpage"
			redirect_to controller: "promodigi", action: "landing_page", params: request.query_parameters and return
		end
	end

	def landing_page
		@user = User.find(params[:user])
		@landing_page = LandingPage.find(params[:landing_page])
		@contact = Contact.new(:email => "", :subject => "", :message => "")
		@og_image = @landing_page.campaign.microposts.where(category: "facebook_linked_post").first.picture.url
		@og_image = @landing_page.campaign.microposts.where(category: "facebook_post").first.picture.url unless @og_image
	end

	def send_lead
		user = User.find(params[:user])
		lead_name = params[:contact][:name]
		email = params[:contact][:email]
    campaign = params[:contact][:campaign]
    message = params[:contact][:message]

    contact = Contact.new( email: email, message: message, name: lead_name, subject: "You've received a lead!")
    logger.info( "VALID: #{contact.valid?}")
    if contact.valid?
      contact.send_lead(email, campaign, message, lead_name, user)
      flash[:success] = "Message sent, thank you for reaching out!"
    else
      flash[:danger] = "We're sorry, there was an issue sending out your message."
    end
    redirect_to landing_page_path(user: user.id, landing_page: params[:landing_page]) and return
	end

end

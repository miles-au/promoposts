class OnboardingController < ApplicationController
	before_action :correct_user

	def show
		@step = current_user.onboarding_stage
	end

	def next_stage
		current_user.onboarding_stage += 1
		current_user.save
		@step = current_user.onboarding_stage
		respond_to do |format|
      format.html
      format.js
    end
	end

	def update_user
		if params[:slug].empty?
			current_user.slug = current_user.id
		else
			current_user.slug = params[:slug]
		end
		current_user.company = params[:company]
		current_user.website = params[:website]
		current_user.color = params[:color]

		if current_user.save
			current_user.onboarding_stage += 1
			current_user.save
		else
			@errors = current_user.errors.messages
		end
		@step = current_user.onboarding_stage
		respond_to do |format|
      format.html
      format.js
    end
	end

	private
		def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

end

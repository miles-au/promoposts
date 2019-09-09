class AccountsController < ApplicationController
  before_action :logged_in_user

  def edit
  	#list all available accounts
  	@account = Account.new
  	@user = current_user
    # if !current_user.timezone
    #   current_user.timezone = Time.zone_offset(Time.now.zone)
    #   current_user.save
    # end

  	@providers = Account.provider_array
  	@data = {}

    #sort accounts by platform
  	@providers.each do |provider|
  		@data[provider] = []
  		@user.accounts.each do |account|
  			if account['provider'] == provider.downcase
  				@data[provider].push(account)
  			end
  		end
  	end

  end

  def remove_page
    @account = current_user.accounts.find(params[:id])
    @account.destroy
    redirect_to accounts_edit_path
  end

  def connect
  end

  def disconnect
  	provider = params['provider']
  	user = current_user

  	case provider
  	  when "facebook"
        User.unauthorize_facebook(user)
      when "linkedin"
        User.unauthorize_linkedin(user)
      when "twitter"
        User.unauthorize_twitter(user)
      when "buffer"
  		  User.unauthorize_buffer(user)
      when "pinterest"
        User.unauthorize_pinterest(user)
  	end

  	flash[:success] = "Disconnected #{provider} account."
  	redirect_to '/accounts/edit'
  end

  private

  	def account_params
      params.permit(:provider, :subscribe, :unsubscribe)
    end

end
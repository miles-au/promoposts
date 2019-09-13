class AccountsController < ApplicationController
  before_action :logged_in_user

  def edit
    clear_location
    
  	#list all available accounts
  	@account = Account.new
  	@user = current_user

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
    current_user.send("unauthorize_#{params['provider']}")
  	flash[:success] = "Disconnected #{params['provider']} account."
  	redirect_to '/accounts/edit'
  end

  private

  	def account_params
      params.permit(:provider, :subscribe, :unsubscribe)
    end

end
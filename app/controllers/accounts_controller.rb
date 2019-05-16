class AccountsController < ApplicationController
  before_action :logged_in_user

  def edit
  	#list all available accounts
  	@account = Account.new
  	@user = current_user

  	providers = ["facebook", "linkedin", "instagram", "buffer"]
  	@data = {}

    #sort accounts by platform
  	providers.each do |provider|
  		@data[provider] = []
  		@user.accounts.each do |account|
  			if account['provider'] == provider
  				@data[provider].push(account)
  			end
  		end
  	end

  end

  def update
  	@account = Account.new
  	@user = current_user
    @post_success = []
    @post_failure = []

  	if params[:subscribe] && logged_in?
	  	subs = params[:subscribe]
	  	subs.each do |page|
	  		#if page exists
	  		if page.present?
				#subscribe
				a = @user.accounts.find(page)
				
				page_token = Account.get_token(a.access_token)
				url = "https://graph.facebook.com/v3.1/#{a.account_id}/subscribed_apps"
				x = Net::HTTP.post_form(URI.parse(url), {"access_token" => page_token})
        #puts x.body

				#response
				get_url = URI("https://graph.facebook.com/#{a.account_id}/subscribed_apps")
				get_params = { "access_token" => page_token }
				get_url.query = URI.encode_www_form(get_params)
				y = Net::HTTP.get_response(get_url)
			  #puts y.body

        if x.is_a?(Net::HTTPSuccess)
          a.autoshare = true
          a.save!
          @post_success << a.name
        else
          @post_failure << a.name
        end

	  		end
	  	end
	  end

	  if params[:unsubscribe] || params[:unsubscribe_hidden]
	  	hidden = params[:unsubscribe_hidden] #submits all
	  	unsubs = params[:unsubscribe] #submits the same thing as hidden if checked

	  	# run through all pages(hidden)
	  	hidden.each do |page|
	  		# if unsubscribes don't exist (1 unsubscriber) or unsubscribers doesn't include the page (checkbox was empty)
	  		if !unsubs || !unsubs.include?(page)
				
				#unsubscribe
				a = @user.accounts.find(page)
				
				page_token = Account.get_token(a.access_token)
				url = "https://graph.facebook.com/v3.1/#{a.account_id}/subscribed_apps"
				uri = URI.parse(url)
			  http = Net::HTTP.new(uri.host, uri.port)
			  http.use_ssl = true
			  attribute_url = '?'
			  attribute_url << {"access_token" => page_token}.map{|k,v| "#{k}=#{v}"}.join('&')
			  request = Net::HTTP::Delete.new(uri.request_uri+attribute_url)
			  response = http.request(request)
        #puts response.body

				#response
				get_url = URI("https://graph.facebook.com/#{a.account_id}/subscribed_apps")
				get_params = { "access_token" => page_token }
				get_url.query = URI.encode_www_form(get_params)
				y = Net::HTTP.get_response(get_url)
				#puts y.body

        sub_list = y.body.to_s
        found = false

        if sub_list.include? a.account_id
          found = true
        end

        if y.is_a?(Net::HTTPSuccess) && found == false
          a.autoshare = false
          a.save!
          @post_success << a.name
        else
          @post_failure << a.name
        end

	  		end
	  	end
	  end

    success_map = @post_success.map(&:inspect).join(', ')
    failure_map = @post_failure.map(&:inspect).join(', ')
    provider_string = success_map.gsub!('"', '')
    fail_string = failure_map.gsub!('"', '')

    if @post_success.count < 1 && @post_failure.count < 1
      flash[:success] = "Autoshare settings up to date."
    elsif @post_success.count < 1
      flash[:danger] = "Sorry, we were unable to update autoshare for: #{fail_string}"
    elsif @post_failure.count < 1
      flash[:success] = "Autoshare settings updated for: #{provider_string}"
    else
      flash[:success] = "Autoshare settings updated for: #{provider_string} | Autoshare update failed: #{fail_string}"
    end
	  
  	redirect_to '/accounts/edit'

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
      when "buffer"
  		User.unauthorize_buffer(user)
  	end

  	flash[:success] = "Disconnected #{provider} account."
  	redirect_to '/accounts/edit'
  end

  private

  	def account_params
      params.permit(:provider, :subscribe, :unsubscribe)
    end

end
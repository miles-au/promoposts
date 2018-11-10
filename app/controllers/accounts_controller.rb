class AccountsController < ApplicationController

  def edit
  	#list all available accounts
  	@account = Account.new
  	@user = current_user

  	providers = ["facebook", "linkedin", "instagram", "buffer"]
  	data = {}


  	providers.each do |provider|
  		data[provider] = []
  		@user.accounts.each do |account|
  			if account['provider'] == provider
  				data[provider].push(account)
  			end
  		end
  	end

  	#data{{'facebook' => [account, account, account]}, {'linkedin' => [account, account, account]}}

  	puts "DATA: #{data}"
  	@fb_accounts = data['facebook']
  	@linkedin_accounts = data['linkedin']
  	@instagram_accounts = data['instagram']
  	@buffer_accounts = data['buffer']

  end

  def update
  	@account = Account.new
  	@user = User.find(params[:user_id])

  	if params[:subscribe]
	  	subs = params[:subscribe]
	  	subs.each do |page|
	  		#if page exists
	  		if !page.empty?
				#subscribe
				a = Account.find_by_account_id(page.to_s)
				a.autoshare = true
				a.save!
				page_token = @user.facebook.get_object(page, fields:"access_token")['access_token']
				url = 'https://graph.facebook.com/v3.1/'+ page +'/subscribed_apps'
				x = Net::HTTP.post_form(URI.parse(url), {"access_token" => page_token})
				puts x.body

				#response
				get_url = URI('https://graph.facebook.com/' + page + '/subscribed_apps')
				get_params = { "access_token" => page_token }
				get_url.query = URI.encode_www_form(get_params)
				y = Net::HTTP.get_response(get_url)
				puts y.body if y.is_a?(Net::HTTPSuccess)

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
				a = Account.find_by_account_id(page.to_s)
				a.autoshare = false
				a.save!
				page_token = @user.facebook.get_object(page, fields:"access_token")['access_token']
				url = 'https://graph.facebook.com/v3.1/'+ page +'/subscribed_apps'
				uri = URI.parse(url)
			    http = Net::HTTP.new(uri.host, uri.port)
			    http.use_ssl = true
			    attribute_url = '?'
			    attribute_url << {"access_token" => page_token}.map{|k,v| "#{k}=#{v}"}.join('&')
			    request = Net::HTTP::Delete.new(uri.request_uri+attribute_url)
			    response = http.request(request)
			    puts response.body

				#response
				get_url = URI('https://graph.facebook.com/' + page + '/subscribed_apps')
				get_params = { "access_token" => page_token }
				get_url.query = URI.encode_www_form(get_params)
				y = Net::HTTP.get_response(get_url)
				puts y.body if y.is_a?(Net::HTTPSuccess)

	  		end
	  	end
	end

	flash[:success] = "Updated autoshare preferences."
  	redirect_to '/accounts/edit'

  end

  def connect
  end

  private

  	def account_params
      params.permit(:provider, :user_id.to_s, :account_id, :subscribe, :unsubscribe)
    end

end
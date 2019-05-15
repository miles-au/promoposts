class WebhooksController < ApplicationController
	protect_from_forgery :except => :facebook
	protect_from_forgery :except => :delete_data

	before_action :webhook_check, only: [:facebook]

	def facebook
	  if @changes['value']['published']
		if @changes['value']['published'] == 0 || @changes['value']['published'] == false || @changes['value']['published'] == "0"
		  head :accepted and return
		end
	  else
	  	head :not_implemented and return
	  end

	  #field = @changes['field']
	  item = @changes['value']['item']

	  if ["album", "address", "comment", "connection", "coupon", "event", "experience", "group", "group_message", "interest", "like", "mention", "milestone", "note", "page", "picture", "platform-story", "photo-album", "profile", "rating", "reaction", "relationship-status", "story", "timeline cover", "tag", "video"].include?(item)
	  	head :accepted and return
	  end

	  if @changes['value']['message']
	  	content = @changes['value']['message']
	  end
	  account_id = @changes['value']['from']['id']
	  if item == "photo"
	  	picture = @changes['value']['link']
	  elsif item == "share"
	  	external_link = @changes['value']['link']

		y = Net::HTTP.get_response(URI.parse(external_link))
		if y.is_a?(Net::HTTPSuccess)
			doc = Nokogiri::HTML(y.body)
			picture = doc.at('meta[property="og:image"]')['content']
		else
			picture = nil
		end

	  elsif item == "status"
	  	if @changes['value']['photos']
	  	  picture = @changes['value']['photos'].first
	  	else
	  	  picture = nil
	  	end
	  else
	  	picture = nil
	  end

	  @account = Account.find_by_account_id(account_id)
	  if @account
	  	#last post - to counter share to facebook page, webhook shares back to promo posts
	  	
	  	if @account.last_share_time
		  	plus_five = @account.last_share_time + 5.seconds
		  	#received post from facebook
		  	created_time = @changes['value']['created_time']
		  	received_time = Time.zone.strptime(created_time.to_s, '%s')

		  	if content
			  	if received_time < plus_five
			  	  head :accepted and return
			  	end
			else
				if received_time < plus_five
					head :accepted and return
			  	end
			end
		end

	  	if @account.autoshare == true
		  user_id = @account.user_id
		  @micropost = Micropost.new(:content => content, :user_id => user_id, :remote_picture_url => picture, :category => "news")
		  if external_link
		  	@micropost.external_url = external_link
		  end
		  @micropost.save!
		  #event = Event.new(user_id: user_id, micropost_id: @micropost.id, contribution: 'create')
      	  #event.save
		  head :created and return
		else
		  head :forbidden and return
		end
		 
	  #testing purposes
	  elsif account_id == '1067280970047460' && Rails.env.development?
	  	@account = Account.find_by_account_id('1067280970047460')

	  	if @account && @account.autoshare == true
	  	  user_id = User.find_by_name('Promo Poster').id
		  @micropost = Micropost.new(:content => content, :user_id => user_id, :remote_picture_url => picture)
		  @micropost.save!
		  #event = Event.new(user_id: user_id, micropost_id: @micropost.id, contribution: 'create')
      	  #event.save
		  head :created and return
		else
		  head :not_implemented and return
		end
	  else
	  	head :not_implemented and return
	  end

	end

	def challenge
		if params['hub.verify_token'] == 'cCxiKr91yt87CyQeUhEp'
			render html: params['hub.challenge'] and return
		else
			render html: 'error' and return
		end

		redirect_to root_url
	end

	def unauthorize_facebook
		signed_request = params['signed_request']
	    payload = signed_request.split(".")[1]
	    payload += '=' * (4 - payload.length.modulo(4))

	    decoded_json = Base64.decode64(payload)
	    signed_data = JSON.parse(decoded_json)

	    user_id = signed_data['user_id']
	    user = User.find_by(:fb_uid => user_id)

	    render :json => { message: "Unauthorize request received"}
	    
	end

	def delete_data
	    signed_request = params['signed_request']
	    payload = signed_request.split(".")[1]
	    payload += '=' * (4 - payload.length.modulo(4))

	    decoded_json = Base64.decode64(payload)
	    signed_data = JSON.parse(decoded_json)

	    user_id = signed_data['user_id']
	    user = User.find_by(:fb_uid => user_id)

	    accounts = Accounts.where("user_id = ?", user.id)
	    accounts.each do |page|
	    	page.destroy!
	    end

	    ticket = Ticket.new(:message => "Your data delete request has been completed.")
	    ticket.save!

	    status_url = "#{request.base_url}#{ticket_path(:id => ticket.id)}"

	    user.fb_uid = nil
	    user.fb_oauth_token = nil
	    user.save!

	    render :json => { url: status_url, confirmation_code: ticket.id}
	end

	def webhook_check
		graph = Koala::Facebook::RealtimeUpdates.new( :app_id => ENV['FACEBOOK_KEY'] , :secret => ENV['FACEBOOK_SECRET'])
		if Rails.env.test?
		  legitimate = true
		else
		  legitimate = graph.validate_update(request.body.read, request.env)
		end

		if legitimate
			@changes = params['entry'].first['changes'].first
			verb = @changes['value']['verb']
			if verb != "add"
			  head :non_authoritative_information
			end
		else
		  head :forbidden
		  puts "illegitimate request"
		end
	end

end

class WebhooksController < ApplicationController
	protect_from_forgery :except => :facebook
	protect_from_forgery :except => :delete_data

	def facebook
	  changes = params['entry'].first['changes'].first
	  field = changes['field']
	  item = changes['value']['item']
	  content = changes['value']['message']
	  account_id = changes['value']['from']['id']
	  if item == "photo"
	  	picture = changes['value']['link']
	  else
	  	picture = nil
	  end

	  if @account = Account.find_by_account_id(account_id)
	  	if @account.autoshare == true
		  user_id = @account.user_id
		  @micropost = Micropost.new(:content => content, :user_id => user_id, :remote_picture_url => picture)
		  @micropost.save!
		end
		 
	  #testing purposes
	  elsif account_id == '1067280970047460'
	  	@account = Account.find_by_account_id('2315862868426589')

	  	if @account.autoshare == true
	  	  user_id = User.find_by_name('Promo Poster').id
		  @micropost = Micropost.new(:content => content, :user_id => user_id, :remote_picture_url => picture)
		  @micropost.save!
		end
	  end

	  head :ok and return
	  render html: "success"

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

end

class WebhooksController < ApplicationController
	protect_from_forgery :except => :facebook

	def facebook
	  changes = params['entry'].first['changes'].first
	  field = changes['field']
	  item = changes['value']['item']
	  content = changes['value']['message']
	  account_id = changes['value']['from']['id']
	  if item == "photo"
	  	picture = item = changes['value']['link']
	  else
	  	picture = nil
	  end

	  if @account = Account.find_by_account_id(account_id)
		  user_id = @account.user_id
		  @micropost = Micropost.new(:content => content, :user_id => user_id, :remote_picture_url => picture)
		  @micropost.save!
		 
	  #testing purposes
	  elsif account_id == '1067280970047460'
	  	  user_id = '1'
		  @micropost = Micropost.new(:content => content, :user_id => user_id, :remote_picture_url => picture)
		  @micropost.save!

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

end

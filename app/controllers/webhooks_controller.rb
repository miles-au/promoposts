class WebhooksController < ApplicationController
	protect_from_forgery :except => :facebook

	def facebook
	  changes = params['entry'].first['changes'].first
	  field = changes['field']
	  content = changes['value']['message']
	  account_id = changes['value']['from']['id']

	  if @account = Account.find_by_account_id(account_id)
		  user_id = @account.user_id
		  @micropost = Micropost.new(:content => content, :user_id => user_id)
		  @micropost.save!
		 
	  elsif account_id == '1067280970047460'
	  	  user_id = '102'
		  @micropost = Micropost.new(:content => content, :user_id => user_id)
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

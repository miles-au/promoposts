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

  def update_on_schedule_all
    puts "PARAMS: #{params}"
    current_user.accounts.each do |account|
      set_onschedule_and_create_scheduled_posts(account, params[:on_schedule] || "0")
    end
  end

  def update_on_schedule
    account = current_user.accounts.find(params[:id])
    if account 
      #update scheduled posts
      set_onschedule_and_create_scheduled_posts(account, params[:account][:on_schedule])
    else
      render status: :forbidden, text: "You do not have access to this account."
    end

    # respond_to do |format|
    #   format.html
    #   format.js
    # end
  end

  def set_onschedule_and_create_scheduled_posts(account, value)
    if value == "1"
      # get scheduled posts from admin
      topic_ids = account.user.topics.pluck(:id)
      posts = User.first.scheduled_posts.where("post_time > ? AND platform = ? AND topic_id IN (?)", Time.now.getutc, account.platform, topic_ids)
      posts.each do |post|
          external_url = post.micropost.campaign.landing_page.get_landing_page_url(account.user) rescue nil
          new_scheduled_post = ScheduledPost.new( user_id: account.user.id,
                                                  account_id: account.id,
                                                  micropost_id: post.micropost_id,
                                                  picture_url: account.user.get_picture_with_default_overlay(post.picture_url, post.post_time + 3.months),
                                                  caption: post.caption,
                                                  platform: post.platform,
                                                  post_time: (post.post_time - account.user.current_offset),
                                                  external_url: external_url )
          new_scheduled_post.save
      end
    elsif value == "0"
      account.scheduled_posts.all.destroy_all
    end

    account.on_schedule = value
    account.save

  end

  private

  	def account_params
      params.permit(:provider, :subscribe, :unsubscribe)
    end

end
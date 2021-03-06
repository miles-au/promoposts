class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_post, :submit_share_post, :download_post_page, :download_post ]
  before_action :correct_or_admin_user, only: [:destroy]

  protect_from_forgery with: :exception

  require 'uri'
  require 'open-uri'
  require 'net/http'
  require 'net/https'
  require 'json'

=begin
  rescue_from Koala::Facebook::APIError do |exception|
    puts "KOALA ERROR"
    puts exception.fb_error_code
    puts exception.fb_error_type
    if exception.fb_error_code == 190 || exception.fb_error_type == 200
      puts "We were unable to get the required permissions"
    elsif exception.fb_error_code == 32
      puts "Thanks for the enthusiasm! Unfortunately you are making too many requests."
    elsif exception.fb_error_code == 506
      puts "It looks like you've shared this post recently!"
    else
      puts "Sorry, something went wrong."
    end
    @facebook_failed = true
    #redirect_back(fallback_location: root_path)
  end
=end

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.content.blank? && @micropost.picture.url
      @micropost.content = "<image only>"
    end
    if @micropost.save
      flash[:success] = "Your promo post is live!"
      # if @micropost.category == 'question'
      #   question_notification_emails
      # end
      if @micropost.campaign_id
        redirect_to campaign_path(id: @micropost.campaign_id)
      else
        redirect_to @micropost
      end
    else
      render 'microposts/new'
    end
  end

  def new
    @micropost = current_user.microposts.build
  end

  def destroy
    @micropost.destroy
    flash[:success] = "Promo post deleted"
    redirect_to root_url
  end

  def show
    @micropost = Micropost.find(params[:id])
    @topics = Topic.find(@micropost.scheduled_posts.pluck(:topic_id)).uniq
    if current_user
      @caption = @micropost.content.gsub("<WEBSITE>", current_user.website || "")
    else
      @caption = @micropost.content.gsub("<WEBSITE>", "")
    end
    if @micropost.campaign_id
      @campaign = Campaign.find(@micropost.campaign_id)
    end
    @user = @micropost.user

    if logged_in?
      platform_accounts = current_user.accounts
      @fbaccounts = platform_accounts.where(:provider => "facebook", :user_id => current_user.id)
      @linkedinaccounts = platform_accounts.where(:provider => "linkedin", :user_id => current_user.id)
      @bufferaccounts = platform_accounts.where(:provider => "buffer", :user_id => current_user.id)
    end
  end

  def share_post
    @micropost = Micropost.find(params[:id])
    @scheduled_post = ScheduledPost.new()
    @check_accounts = current_user.check_accounts

    default_overlay = Overlay.find(current_user.setting.default_overlay_id) rescue nil
    @default_location = current_user.setting.default_overlay_location rescue nil

    @overlays = current_user.overlays.map{ | k | k.id == current_user.setting.default_overlay_id ? nil : [k.name, k.picture.url, k.id] }.compact
    @overlays.unshift(["none", "", ""])
    if default_overlay
      @overlays.unshift( [ default_overlay.name, default_overlay.picture.url, default_overlay.id ] )
    end
    @users_time = current_user.utc_to_user_time(Time.now.getutc)
  end

  def submit_share_post
    micropost = Micropost.find(params[:id])
    overlay = Overlay.find(params[:overlay][:id]) rescue nil
    message = params['message']
    post_date = params["post_date"] rescue Date.today
    accounts = current_user.accounts.where('id IN (?)', params[:pages])
    @success_string = []
    post_to_buffer = false
    if params[:to_schedule]
      is_scheduled_post = true
      delete_by_date = Date.parse(post_date) + 3.months
    else
      is_scheduled_post = false
      delete_by_date = Date.today + 2.days
    end

    if overlay.present?
      picture_url = Micropost.create_overlay_picture( micropost.picture.url,
                                                      overlay,
                                                      params[:overlay][:left],
                                                      params[:overlay][:top],
                                                      params[:overlay][:width],
                                                      params[:overlay][:height],
                                                      delete_by_date)
      picture_url = root_url + picture_url unless Rails.env.production?
    else
      picture_url = micropost.picture.url
      picture_url = root_url.chop + picture_url unless Rails.env.production?
    end
    puts "PICTURE_URL: #{picture_url}"
    
    #scheduled post?
    if is_scheduled_post
      accounts.each do |page|
        best_post_time = Account.best_post_time(page.platform, post_date.to_time )
        new_scheduled_post = ScheduledPost.new( user_id: current_user.id,
                                                account_id: page.id,
                                                micropost_id: micropost.id,
                                                picture_url: picture_url,
                                                caption: message,
                                                platform: page.platform,
                                                post_time: (best_post_time - current_user.current_offset) )
        new_scheduled_post.save
      end
      flash[:success] = "Your post schedule has been updated"
      redirect_to scheduled_posts_path and return
    else
      accounts.each do |page|
        post_to_buffer = true if page.provider == "buffer"
        resp = Micropost.send("share_to_#{page.provider}", nil, page, message, picture_url, current_user)

        if resp == "success"
          @success_string << "<span class='glyphicon glyphicon-ok'></span> #{page.name} - Success"
        else
          @success_string << "<span class='glyphicon glyphicon-remove'></span> #{page.name} - Failed"
        end
      end
    end

    if current_user != micropost.user_id
      micropost.shares = micropost.shares + 1 rescue 1
      micropost.save
      track = Track.new(user_id: current_user.id, category: micropost.category, asset_num: micropost.id, act: "share")
      track.save
    end

    if post_to_buffer
      buffer_link = "https://publish.buffer.com/profile/#{current_user.buffer_uid}/tab/queue"
      @success_string << "<a target='_blank' href='#{buffer_link}'>Click here to go to your Buffer Queue</a>"
    end
    flash[:success] = @success_string.join("<br/>").html_safe

    redirect_to micropost
  end

  def download_post_page
    @micropost = Micropost.find(params[:id])
    if @micropost.campaign_id
      @campaign = Campaign.find(@micropost.campaign_id)
    end
    @check_accounts = current_user.check_accounts

    default_overlay = Overlay.find(current_user.setting.default_overlay_id) rescue nil
    @default_location = current_user.setting.default_overlay_location rescue nil

    @overlays = current_user.overlays.map{ | k | k.id == current_user.setting.default_overlay_id ? nil : [k.name, k.picture.url, k.id] }.compact
    @overlays.unshift(["none", "", ""])
    if default_overlay
      @overlays.unshift( [ default_overlay.name, default_overlay.picture.url, default_overlay.id ] )
    end

  end

  def download_post
    micropost = Micropost.find(params[:id])
    category = micropost.category || "picture"
    overlay = Overlay.find(params[:overlay][:id]) rescue nil

    if overlay.present?
      picture_url = Micropost.create_overlay_picture(
        micropost.picture.url,
        overlay,
        params[:overlay][:left],
        params[:overlay][:top],
        params[:overlay][:width],
        params[:overlay][:height],
        Date.tomorrow)
    else
      picture_url = micropost.picture.url
    end

    if current_user != micropost.user
      if micropost.downloads
        micropost.downloads += 1
      else 
        micropost.downloads = 1
      end
      micropost.save
    end

    track = Track.new(user_id: current_user.id, category: micropost.category, asset_num: micropost.id, act: "download")
    track.save

    picture_url = root_url + picture_url unless Rails.env.production?
    send_data(open(picture_url).read.force_encoding('BINARY'), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
    
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :picture, :category, :external_url, :campaign_id)
    end

    def correct_or_admin_user
      if current_user.admin == true || current_user.microposts.find_by(id: params[:id])
        @micropost = Micropost.find(params[:id])
      else
        redirect_to root_url
      end
    end

    def download_log
      @download_logger ||= Logger.new("#{Rails.root}/log/downloads.log")
    end

end
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
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    if @micropost.campaign_id
      @campaign = Campaign.find(@micropost.campaign_id)
    end
    @comment = Comment.new
    @comments = Comment.where(:micropost_id => @micropost.id, :head => nil)
    @comments = @comments.all.order(created_at: :desc).sort_by {|x| x.points }.reverse
    @user = @micropost.user

    if logged_in?
      platform_accounts = current_user.accounts
      @fbaccounts = platform_accounts.where(:provider => "facebook", :user_id => current_user.id)
      @linkedinaccounts = platform_accounts.where(:provider => "linkedin", :user_id => current_user.id)
      @bufferaccounts = platform_accounts.where(:provider => "buffer", :user_id => current_user.id)
    end
  end

  def share_post
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    @check_accounts = current_user.check_accounts

    default_overlay = Overlay.find(current_user.setting.default_overlay_id) rescue nil
    @default_location = current_user.setting.default_overlay_location rescue nil

    @overlays = current_user.overlays.map{ | k | k.id == current_user.setting.default_overlay_id ? nil : [k.name, k.picture.url, k.id] }.compact
    @overlays.unshift(["none", "", ""])
    if default_overlay
      @overlays.unshift( [ default_overlay.name, default_overlay.picture.url, default_overlay.id ] )
    end

  end

  def submit_share_post
    micropost = Micropost.find(params[:id])
    overlay = Overlay.find(params[:overlay][:id]) rescue nil
    message = params['message']
    post_date = params["post_date"] rescue Date.today
    accounts = current_user.accounts.where('id IN (?)', params[:pages])
    @success_string = []
    @create_share_event = false
    post_to_buffer = false

    if overlay.present?
      file_url = Micropost.create_overlay_picture(
        micropost.picture.url,
        overlay,
        params[:overlay][:left],
        params[:overlay][:top],
        params[:overlay][:width],
        params[:overlay][:height])
      file_name = file_url.split('/').last
      picture_url = "#{root_url}filters/#{file_name}"
    elsif Rails.env.production?
      picture_url = "" + micropost.picture.url
    else
      picture_url = root_url + micropost.picture.url
    end

    #scheduled post?
    if Date.parse(post_date) > Date.today
      accounts.each do |page|
        new_scheduled_post = ScheduledPost.new()
        new_scheduled_post.user_id = current_user.id
        new_scheduled_post.account_id = page.id
        new_scheduled_post.micropost_id = micropost.id
        new_scheduled_post.picture_url = picture_url
        new_scheduled_post.caption = message
        best_post_time = Account.best_post_time(page.platform, DateTime.parse(post_date) )
        utf_offset_s = Time.zone_offset(Time.now.zone)
        new_scheduled_post.post_time = (best_post_time.to_time - utf_offset_s).to_datetime
        new_scheduled_post.save
      end
      flash[:success] = "Your post schedule has been updated"
      redirect_to scheduled_posts_path and return
    end
    
    accounts.each do |page|
      case page.provider
        when "facebook"
          resp = Micropost.share_to_facebook(nil, page, message, picture_url, current_user)
        when "linkedin"
          resp = Micropost.share_to_linkedin(nil, page, message, picture_url, current_user)
        when "twitter"
          resp = Micropost.share_to_twitter(nil, page, message, picture_url, current_user)
        when "buffer"
          post_to_buffer = true
          resp = Micropost.share_to_buffer(nil, page, message, picture_url, current_user)
        when "pinterest"
          resp = Micropost.share_to_pinterest(nil, page, message, picture_url, current_user)
        else
      end

      if resp == "success"
        @success_string << "<span class='glyphicon glyphicon-ok'></span> #{page.name} - Success"
        @create_share_event = true
      else
        @success_string << "<span class='glyphicon glyphicon-remove'></span> #{page.name} - Failed"
      end
    end

    if current_user != micropost.user_id
      if micropost.shares
        micropost.shares += 1
      else 
        micropost.shares = 1
      end
      micropost.save
      track = Track.new(user_id: current_user.id, category: micropost.category, asset_num: micropost.id, act: "share")
      track.save
    end

    if post_to_buffer
      buffer_link = "https://publish.buffer.com/profile/#{current_user.buffer_uid}/tab/queue"
      @success_string << "<a target='_blank' href='#{buffer_link}'>Go to your Buffer Queue</a>"
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
      file_url = Micropost.create_overlay_picture(
        micropost.picture.url,
        overlay,
        params[:overlay][:left],
        params[:overlay][:top],
        params[:overlay][:width],
        params[:overlay][:height])
      file_name = file_url.split('/').last
      picture_url = "#{root_url}filters/#{file_name}"
    elsif Rails.env.production?
      picture_url = "" + micropost.picture.url
    else
      picture_url = root_url+ micropost.picture.url
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

    if Rails.env.production?
      send_data(open(picture_url).read.force_encoding('BINARY'), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
    else
      send_data(open(picture_url).read.force_encoding('BINARY'), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
    end

  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :picture, :category, :shareable, :external_url, :campaign_id)
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
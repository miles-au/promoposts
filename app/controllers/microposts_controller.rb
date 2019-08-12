class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_post]
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
  end

  def submit_share_post
    micropost = Micropost.find(params[:id])
    message = params['message']
    accounts = current_user.accounts.where('id IN (?)', params[:pages])
    @success_string = []
    @create_share_event = false

    if Rails.env.production?
      base_url = ""
    else
      base_url = root_url
    end
    
    accounts.each do |page|
      case page.provider
      when "facebook"
        resp = Micropost.share_to_facebook(micropost, page, message, base_url, current_user)
      when "linkedin"
        resp = Micropost.share_to_linkedin(micropost, page, message, base_url, current_user)
      when "twitter"
        resp = Micropost.share_to_twitter(micropost, page, message, base_url, current_user)
      when "buffer"
        resp = Micropost.share_to_buffer(micropost, page, message, base_url, current_user)
      when "pinterest"
        resp = Micropost.share_to_pinterest(micropost, page, message, base_url, current_user)
      else
      end

      if resp == "success"
        @success_string << "<span class='glyphicon glyphicon-ok'></span> #{page.name} - Success"
        @create_share_event = true
      else
        @success_string << "<span class='glyphicon glyphicon-remove'></span> #{page.name} - Failed"
      end
    end

    if @create_share_event && current_user != micropost.user_id
      #create event
      @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id, contribution: 'share')
      @event.save!

      #create notification
      @notification = Notification.new(:user_id => micropost.user_id, :message => "#{current_user.name} shared your post.", :category => "share", :destination_id => micropost.id, :obj => "micropost" )
      @notification.save!

      if micropost.shares
        micropost.shares += 1
      else 
        micropost.shares = 1
      end
      micropost.save
      track = Track.new(user_id: current_user.id, category: micropost.category, asset_num: micropost.id, act: "share")
      track.save
    end

    flash[:success] = @success_string.join("<br/>").html_safe 

    redirect_to micropost
  end

  def mark_top_comment
    micropost = Micropost.find(params['micropost_id'])
    micropost.top_comment = params['comment_id']
    micropost.save

    flash[:success] = "Thank you for marking a top comment!"
    redirect_to micropost
  end

  def download_picture
    micropost = Micropost.find(params[:id])
    category = micropost.category || "picture"
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
      send_data(open(micropost.picture.url.read.force_encoding('BINARY')), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
    else
      send_data(open("#{request.protocol}#{request.subdomain}.#{request.domain}#{micropost.picture.url}").read.force_encoding('BINARY'), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
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
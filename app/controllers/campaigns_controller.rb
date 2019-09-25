require 'open-uri'

class CampaignsController < ApplicationController
  before_action :logged_in_user, only: [:new, :edit, :create, :share_campaign, :submit_share_campaign, :update, :download_campaign_page, :download_assets]
  before_action :correct_or_admin_user, only: [:destroy, :edit, :update]

  # GET /campaigns
  # GET /campaigns.json
  def index
    redirect_to root_path(:feed => "campaign")
  end

  # GET /campaigns/1
  # GET /campaigns/1.json
  def show
    @campaign = Campaign.find(params[:id])
    if @campaign.landing_page
      @landing_page = @campaign_landing_page
    else
      @landing_page = LandingPage.new
    end
    if current_user
      @caption = @campaign.content.gsub("<WEBSITE>", current_user.website || "")
    else
      @caption = @campaign.content.gsub("<WEBSITE>", "")
    end
  end

  # GET /campaigns/new
  def new
    @campaign = Campaign.new
  end

  # GET /campaigns/1/edit
  def edit
    @campaign = Campaign.find(params[:id])
    redirect_to @campaign
  end

  # POST /campaigns
  # POST /campaigns.json

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    #@campaign.microposts.first.user_id = current_user.id
    #@campaign.microposts.first.shareable = true

    if @campaign.save
      flash[:success] = "Your campaign has been created."
      redirect_to @campaign
    else
      render 'campaigns/new'
    end
  end

  # PATCH/PUT /campaigns/1
  # PATCH/PUT /campaigns/1.json
  def update
    @campaign = current_user.campaigns.find(params[:id])
    puts "PARAMS: #{campaign_params}"
    @campaign.update_attributes(campaign_params)
    @campaign.microposts.last.user_id = current_user.id
    @campaign.microposts.last.shareable = true

    if @campaign.save
      flash[:success] = "Your campaign has been updated."
      redirect_to @campaign
    else
      respond_to do |format|
        format.html
        format.js
      end
    end
  end

  # DELETE /campaigns/1
  # DELETE /campaigns/1.json
  def destroy
    campaign_name = @campaign.name
    @campaign.destroy
    flash[:success] = "Campaign: #{campaign_name} deleted."
    redirect_to root_url
  end

  def download_campaign_page
    @campaign = Campaign.find(params[:id])
    @bg_images = @campaign.microposts.map { |key| [ key.id, key.picture.url ] }
    default_overlay = Overlay.find(current_user.setting.default_overlay_id) rescue nil
    @default_location = current_user.setting.default_overlay_location rescue nil

    @overlays = current_user.overlays.map{ | k | k.id == current_user.setting.default_overlay_id ? nil : [k.name, k.picture.url, k.id] }.compact
    @overlays.unshift(["none", "", ""])
    if default_overlay
      @overlays.unshift( [ default_overlay.name, default_overlay.picture.url, default_overlay.id ] )
    end

    @overlay_locations = [  [ "Top Left" , "nw" ],
                            [ "Top Right" , "ne" ],
                            [ "Bottom Left" , "sw" ],
                            [ "Bottom Right" , "se" ]
                          ]
    @overlay_select = current_user.overlays.pluck(:name, :id)
    @overlay_select.unshift(["none" , nil])
  end

  def download_assets
    campaign = Campaign.find(params[:id])
    #working folder
    folder_path = "#{Rails.root}/public/campaign_zips/#{current_user.id}"
    #destination zip file
    zipfile_path = "#{folder_path}/#{current_user.id}.zip"

    #delete current zip file if it exists
    File.delete(zipfile_path) if File.exist?(zipfile_path)
    #delete current user's downloads folder if it exists
    FileUtils.remove_dir(folder_path) if Dir.exist?(folder_path)
    #recreate the user's download folder
    FileUtils.mkdir_p(folder_path)

    Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
      files_added = []
      campaign.microposts.each do |asset|
        overlay = Overlay.find(campaign_microposts_params[:"#{asset.id}"][:overlay][:id]) rescue ""
        # puts "OVERLAY ID: #{overlay.id}" rescue "NO OVERLAY"

        #track downloads
        if current_user.id != asset.user_id
          if asset.downloads
            asset.downloads += 1
          else 
            asset.downloads = 1
          end
          asset.save
        end

        #handle duplicate names
        new_file_name = "#{asset.category}.png"
        if files_added.include?(new_file_name)
          n = 2
          ext = File.extname(new_file_name)
          base = File.basename(new_file_name, ext)
          new_name = "#{base}_#{n}#{ext}"
          while files_added.include? new_name
            n += 1
            new_name = "#{base}_#{n}#{ext}"
          end
          new_file_name = new_name
        end

        if Rails.env.production?
          #production
          if overlay.present?
            picture_url = Micropost.create_overlay_picture(
              asset.picture.url,
              overlay,
              campaign_microposts_params[:"#{asset.id}"][:overlay][:left],
              campaign_microposts_params[:"#{asset.id}"][:overlay][:top],
              campaign_microposts_params[:"#{asset.id}"][:overlay][:width],
              campaign_microposts_params[:"#{asset.id}"][:overlay][:height],
              Date.tomorrow)
          else
            picture_url = asset.picture.url
          end

          open("public/campaign_zips/#{asset.picture.url.split('/').last}", 'wb') do |file|
            file << open(picture_url).read
          end
          picture_url = "public/campaign_zips/#{asset.picture.url.split('/').last}"
        else
          #development
          if overlay.present?
            picture_url = "public/#{picture_url}"
          else
            picture_url = asset.picture.path
          end
        end

        zipfile.add(new_file_name, picture_url)
        files_added << new_file_name

      end
    end

    send_data( open(zipfile_path).read.force_encoding('BINARY'), :type => 'application/zip', :filename => "campaign_#{campaign.name}.zip", disposition: 'attachment')

    track = Track.new(user_id: current_user.id, category: "campaign", asset_num: campaign.id, act: "download")
    track.save

    FileUtils.rm_rf(folder_path) if File.exist?(folder_path)

  end

  def share_campaign
    @campaign = Campaign.find(params[:id])
    @scheduled_post = ScheduledPost.new()
    @check_accounts = current_user.check_accounts

    default_overlay = Overlay.find(current_user.setting.default_overlay_id) rescue nil
    @default_location = current_user.setting.default_overlay_location rescue nil

    @overlays = current_user.overlays.map{ | k | k.id == current_user.setting.default_overlay_id ? nil : [k.name, k.picture.url, k.id] }.compact
    @overlays.unshift(["none", "", ""])
    @overlays.unshift( [ default_overlay.name, default_overlay.picture.url, default_overlay.id ] ) if default_overlay

    @overlay_locations = [  [ "Top Left" , "nw" ],
                            [ "Top Right" , "ne" ],
                            [ "Bottom Left" , "sw" ],
                            [ "Bottom Right" , "se" ]]
    @overlay_select = current_user.overlays.pluck(:name, :id)
    @overlay_select.unshift(["none" , nil])
    @users_time = current_user.utc_to_user_time(Time.now.getutc)
  end

  def submit_share_campaign
    campaign = Campaign.find(params[:id])
    message = params['message']
    accounts = current_user.accounts.where('id IN (?)', params[:pages])
    post_date = params["post_date"] rescue Date.today
    if campaign.landing_page
      external_url = campaign.landing_page.get_landing_page_url(current_user)
    else
      external_url = nil
    end
    @success_string = []
    post_to_buffer = false
    if params[:to_schedule]
      is_scheduled_post = true
      delete_by_date = Date.parse(post_date) + 3.months
    else
      is_scheduled_post = false
      delete_by_date = Date.today + 2.days
    end

    accounts.each do |page|
      micropost = Micropost.find(params[:microposts]["#{page.platform}"][:post_id])
      overlay = Overlay.find(params[:microposts]["#{page.platform}"][:overlay][:id]) rescue nil
      if overlay
        picture_url = Micropost.create_overlay_picture( micropost.picture.url,
                                                        overlay,
                                                        params[:microposts]["#{page.platform}"][:overlay][:left],
                                                        params[:microposts]["#{page.platform}"][:overlay][:top],
                                                        params[:microposts]["#{page.platform}"][:overlay][:width],
                                                        params[:microposts]["#{page.platform}"][:overlay][:height],
                                                        delete_by_date)
        picture_url = root_url + picture_url if Rails.env.development?
      else
        picture_url = micropost.picture.url
        picture_url = root_url + picture_url.last(-1) unless Rails.env.production?
      end

      #scheduled post?
      if is_scheduled_post
        best_post_time = Account.best_post_time(page.platform, post_date.to_time )
        new_scheduled_post = ScheduledPost.new( user_id: current_user.id,
                                                account_id: page.id,
                                                micropost_id: micropost.id,
                                                picture_url: picture_url,
                                                caption: message,
                                                platform: page.platform,
                                                post_time: (best_post_time - current_user.current_offset),
                                                external_url: external_url )
        new_scheduled_post.save
      else
        #not scheduled post
        post_to_buffer = true if page.provider == "buffer"
        resp = Micropost.send("share_to_#{page.provider}", external_url, page, message, picture_url, current_user)

        if resp == "success"
          @success_string << "<span class='glyphicon glyphicon-ok'></span> #{page.name} - Success"
          micropost.shares = micropost.shares + 1 rescue 1
          micropost.save
        else
          @success_string << "<span class='glyphicon glyphicon-remove'></span> #{page.name} - Failed"
        end
      end

    end

    if is_scheduled_post
      flash[:success] = "Your post schedule has been updated"
      redirect_to scheduled_posts_path and return
    end

    if current_user != campaign.user_id
      track = Track.new(user_id: current_user.id, category: "campaign", asset_num: campaign.id, act: "share")
      track.save
    end

    if post_to_buffer
      buffer_link = "https://publish.buffer.com/profile/#{current_user.buffer_uid}/tab/queue"
      @success_string << "<a target='_blank' href='#{buffer_link}'>Go to your Buffer Queue</a>"
    end
    flash[:success] = @success_string.join("<br/>").html_safe 

    redirect_to campaign
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def campaign_params
      params.require(:campaign).permit(:name, :content, microposts_attributes: [ :content, :picture, :category ], landing_page_attributes: [ :splash, :title, :headline, :pic_one, :text_one, :pic_two, :text_two, :pic_three, :text_three ] )
    end

    def campaign_microposts_params
      params.require(:microposts).permit!
    end

    def correct_or_admin_user
      if current_user.admin == true || current_user.campaigns.find_by(id: params[:id])
        @campaign = Campaign.find(params[:id])
      else
        redirect_to root_url
      end
    end

    def download_log
      @download_logger ||= Logger.new("#{Rails.root}/log/downloads.log")
    end
end

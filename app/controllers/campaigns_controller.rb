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

    if Rails.env.production?
      campaign.microposts.each do |post|
        file_name = post.picture.url.split('/').last
        open(folder_path + "#{file_name}", 'wb') do |file|
           file << open(post.picture.url).read
        end
      end
    end

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

        if overlay.present?
          picture_url = Micropost.create_overlay_picture(
            asset.picture.url,
            overlay,
            campaign_microposts_params[:"#{asset.id}"][:overlay][:left],
            campaign_microposts_params[:"#{asset.id}"][:overlay][:top],
            campaign_microposts_params[:"#{asset.id}"][:overlay][:width],
            campaign_microposts_params[:"#{asset.id}"][:overlay][:height],
            Date.tomorrow)
          if Rails.env.development?
            picture_url = "public/#{picture_url}"
          end
        else
          if Rails.env.production?
            picture_url = File.join(folder_path,file_name)
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
    @check_accounts = current_user.check_accounts

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

  def submit_share_campaign
    campaign = Campaign.find(params[:id])
    message = params['message']
    accounts = current_user.accounts.where('id IN (?)', params[:pages])
    post_date = params["post_date"] rescue Date.today
    @success_string = []
    @post_to_buffer = false
    if Date.parse(post_date) > Date.today
      is_scheduled_post = true
    else
      is_scheduled_post = false
    end

    accounts.each do |page|
      micropost = Micropost.find(params[:microposts]["#{page.platform}"][:post_id])
      overlay = Overlay.find(params[:microposts]["#{page.platform}"][:overlay][:id]) rescue nil
      if overlay
        file_url = Micropost.create_overlay_picture(
          micropost.picture.url,
          overlay,
          params[:microposts]["#{page.platform}"][:overlay][:left],
          params[:microposts]["#{page.platform}"][:overlay][:top],
          params[:microposts]["#{page.platform}"][:overlay][:width],
          params[:microposts]["#{page.platform}"][:overlay][:height],
          delete_by_date)
        picture_url = file_url
      else
        if Rails.env.production?
          base_url = ""
        else
          base_url = root_url
        end
        picture_url = base_url + micropost.picture.url
      end

      #scheduled post?
      if is_scheduled_post
        new_scheduled_post = ScheduledPost.new()
        new_scheduled_post.user_id = current_user.id
        new_scheduled_post.account_id = page.id
        new_scheduled_post.micropost_id = micropost.id
        new_scheduled_post.picture_url = picture_url
        new_scheduled_post.caption = message
        best_post_time = Account.best_post_time(page.platform, DateTime.parse(post_date) )
        new_scheduled_post.post_time = (best_post_time.to_time - current_user.current_offset).to_datetime
        new_scheduled_post.save
      else
        #not scheduled post
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
          if micropost.shares
            micropost.shares += 1
          else 
            micropost.shares = 1
          end
          micropost.save
        else
          @success_string << "<span class='glyphicon glyphicon-remove'></span> #{page.name} - Failed"
        end
      end

    end

    if Date.parse(post_date) > Date.today
      flash[:success] = "Your post schedule has been updated"
      redirect_to scheduled_posts_path and return
    end

    if current_user != campaign.user_id
      #create notification
      @notification = Notification.new(:user_id => campaign.user_id, :message => "#{current_user.name} shared your campaign.", :category => "share", :destination_id => campaign.id, :obj => "campaign" )
      @notification.save!

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
      params.require(:campaign).permit(:name, :content, microposts_attributes: [ :content, :picture, :category ])
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

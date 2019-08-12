class CampaignsController < ApplicationController
  before_action :logged_in_user, only: [:new, :edit, :create, :share_campaign, :submit_share_campaign, :update, :download_assets]
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

  def download_assets
    File.delete("#{Rails.root}/public/#{current_user.id}.zip") if File.exist?("#{Rails.root}/public/#{current_user.id}.zip")
    FileUtils.remove_dir("#{Rails.root}/public/downloads/#{current_user.id}") if Dir.exist?("#{Rails.root}/public/downloads/#{current_user.id}/")
    FileUtils.mkdir_p("#{Rails.root}/public/downloads/#{current_user.id}")

    campaign = Campaign.find(params[:id])
    zipfile_name = "#{Rails.root}/public/#{current_user.id}.zip"
    folder_path = "#{Rails.root}/public/downloads/#{current_user.id}/"

    if Rails.env.production?
      campaign.microposts.each do |post|
        file_name = post.picture.url.split('/').last
        open(folder_path + "#{file_name}", 'wb') do |file|
           file << open(post.picture.url).read
        end
      end
    end

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      files_added = []
      campaign.microposts.each do |asset|
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
          file_name = asset.picture.url.split('/').last
          zipfile.add(new_file_name, File.join(folder_path,file_name))
        else
          zipfile.add(new_file_name, asset.picture.path)
        end
        files_added << new_file_name
      end
    end

    send_data( open("#{Rails.root}/public/#{current_user.id}.zip").read.force_encoding('BINARY'), :type => 'application/zip', :filename => "campaign_#{campaign.name}.zip", disposition: 'attachment')

    track = Track.new(user_id: current_user.id, category: "campaign", asset_num: campaign.id, act: "download")
    track.save

    if Rails.env.production?
      File.delete("#{Rails.root}/public/#{current_user.id}.zip") if File.exist?("#{Rails.root}/public/#{current_user.id}.zip")
      FileUtils.rm_rf("#{Rails.root}/public/downloads/#{current_user.id}") if File.exist?("#{Rails.root}/public/downloads/#{current_user.id}")
    end

  end

  def share_campaign
    @campaign = Campaign.find(params[:id])
    @check_accounts = current_user.check_accounts
  end

  def submit_share_campaign
    campaign = Campaign.find(params[:id])
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
      micropost = Micropost.find(params[:microposts]["#{page.platform}"][:post_id])
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

    if @create_share_event && current_user != campaign.user_id
      #create event
      @event = Event.new(user_id: current_user.id, passive_user_id: campaign.user.id, campaign_id: campaign.id, contribution: 'share')
      @event.save!

      #create notification
      @notification = Notification.new(:user_id => campaign.user_id, :message => "#{current_user.name} shared your campaign.", :category => "share", :destination_id => campaign.id, :obj => "campaign" )
      @notification.save!

      track = Track.new(user_id: current_user.id, category: "campaign", asset_num: campaign.id, act: "share")
      track.save
    end

    flash[:success] = @success_string.join("<br/>").html_safe 

    redirect_to campaign

  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def campaign_params
      params.require(:campaign).permit(:name, :content, microposts_attributes: [ :content, :picture, :category ])
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

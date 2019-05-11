class CampaignsController < ApplicationController
  before_action :correct_or_admin_user, only: [:destroy]

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
    @campaign.microposts.first.user_id = current_user.id
    @campaign.microposts.first.shareable = true

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

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def campaign_params
      params.require(:campaign).permit(:name, microposts_attributes: [ :content, :picture, :category ])
    end

    def correct_or_admin_user
      if current_user.admin == true || current_user.campaigns.find_by(id: params[:id])
        @campaign = Campaign.find(params[:id])
      else
        redirect_to root_url
      end
    end
end
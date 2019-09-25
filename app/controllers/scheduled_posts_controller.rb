class ScheduledPostsController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user, only: [:create_global_post, :create_global_campaign, :schedule_global_post]
  before_action :set_scheduled_post, only: [:show, :edit, :update, :destroy]

  # GET /scheduled_posts
  # GET /scheduled_posts.json
  def index
    @time = current_user.utc_to_user_time(Time.now.getutc)
    @backtime = current_user.utc_to_user_time(Time.now.getutc)
    @topics = current_user.topics
    if current_user.admin
      @scheduled_posts = ScheduledPost.all.where.not(topic_id: nil).or(ScheduledPost.where(user_id: current_user.id))
    else
      @scheduled_posts = current_user.scheduled_posts
    end
  end

  def prev_week
    @time = params[:time].to_time
    @backtime = params[:backtime].to_time
    if current_user.admin
      @scheduled_posts = ScheduledPost.all.where.not(topic_id: nil).or(ScheduledPost.where(user_id: current_user.id))
    else
      @scheduled_posts = current_user.scheduled_posts
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def next_week
    @time = params[:time].to_time
    @backtime = params[:backtime].to_time
    if current_user.admin
      @scheduled_posts = ScheduledPost.all.where.not(topic_id: nil).or(ScheduledPost.where(user_id: current_user.id))
    else
      @scheduled_posts = current_user.scheduled_posts
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /scheduled_posts/1
  # GET /scheduled_posts/1.json
  def show
    @users_time = current_user.utc_to_user_time(Time.now.getutc)
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /scheduled_posts/new
  def new
    @scheduled_post = ScheduledPost.new
  end

  def create_global_post
    screened_params = scheduled_post_params

    resp = schedule_global_post(screened_params[:topic_id], screened_params[:platform], screened_params[:micropost_id], screened_params[:post_time] )

    if resp == "success"
      flash[:success] = "Global post scheduled updated"
    elsif resp == "failed"
      flash[:danger] = "Some posts may have failed"
    else
      flash[:danger] = resp
    end

    redirect_to scheduled_posts_path
  end

  def create_global_campaign
    screened_params = scheduled_post_params
    failed = false
    succeeded = false
    campaign = Campaign.find(screened_params[:campaign_id])

    Account.platform_array.map(&:downcase).each do |platform|
      logger.info "PLATFORM: #{platform}"
      micropost = campaign.microposts.where(category: "#{platform}_linked_post").first if campaign.landing_page
      micropost = campaign.microposts.where(category: "#{platform}_post").first unless micropost
      if micropost
        resp = schedule_global_post(screened_params[:topic_id], platform, micropost.id, screened_params[:post_time] )
        if resp == "success"
          succeeded = true
        elsif resp == "failed"
          failed = true
        end
      end
    end

    if succeeded == true && failed == false
      flash[:success] = "Global post scheduled updated"
    else
      flash[:danger] = "Some posts may have failed"
    end

    redirect_to scheduled_posts_path
  end

  def schedule_global_post( topic_id, platform, micropost_id, post_date)
    platform = platform.downcase
    topic = Topic.find(topic_id)
    micropost = Micropost.find(micropost_id)
    post_time = Account.best_post_time(platform, DateTime.parse(post_date))
    failed = false
    succeeded = true
    count = 0

    #create first post from admin
    admin_record = User.first.scheduled_posts.build(topic_id: topic_id, micropost_id: micropost_id, post_time: post_time, picture_url: micropost.picture.url, caption: micropost.content, platform: platform)
    admin_record.save

    topic.users.each do |user|
      # do the picture first so you can share the picture across accounts on the same platform
      accounts = user.accounts.where(platform: platform.downcase, on_schedule: true)
      if accounts.count > 0
        picture_url = user.get_picture_with_default_overlay(  micropost.picture.url, Date.parse(post_date) + 3.months)
      end

      external_url = micropost.campaign.landing_page.get_landing_page_url(user) rescue nil
      accounts.each do |account|
        count += 1
        post = user.scheduled_posts.build(topic_id: topic_id,
                                          micropost_id: micropost.id,
                                          account_id: account.id,
                                          platform: platform,
                                          picture_url: picture_url,
                                          caption: micropost.content.gsub("<WEBSITE>", user.website || ""),
                                          post_time: user.utc_to_user_time(post_time.to_time),
                                          external_url: external_url )
        if post.save
          succeeded = true
        else
          failed = true
        end
      end

    end

    if succeeded == true && failed == false
      return "success"
    else
      return "failed"
    end
  end

  # GET /scheduled_posts/1/edit
  def edit

    respond_to do |format|
      format.html
      format.js
    end
  end

  # POST /scheduled_posts
  # POST /scheduled_posts.json
  def create
    # @scheduled_post = ScheduledPost.new(scheduled_post_params)

    # if @scheduled_post.save
    #   flash[:success] = "Post scheduled"
    # else
    #   flash[:danger] = "unable to schedule post"
    # end

    redirect_to scheduled_posts_path
  end

  # PATCH/PUT /scheduled_posts/1
  # PATCH/PUT /scheduled_posts/1.json
  def update
    if @scheduled_post.status == "POSTED"
      @status = "This has already been posted."
    else
      @scheduled_post.update_attributes(scheduled_post_params)
      @scheduled_post.post_time = current_user.utc_to_user_time(@scheduled_post.post_time) unless !@scheduled_post.account_id
      if @scheduled_post.save
        @status = "Post updated."
      else
        @status = "There was an issue updating this post."
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  # DELETE /scheduled_posts/1
  # DELETE /scheduled_posts/1.json
  def destroy
    @scheduled_post.destroy
    flash[:success] = "Scheduled posting deleted"
    redirect_to scheduled_posts_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scheduled_post
      @scheduled_post = ScheduledPost.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scheduled_post_params
      params.require(:scheduled_post).permit( :topic_id, :platform, :picture_url, :micropost_id, :campaign_id, :post_time, :caption, :external_url )
    end

    def admin_user
      if current_user.admin != true
        render status: :forbidden
      end
    end

end

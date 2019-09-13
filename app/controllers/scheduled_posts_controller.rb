class ScheduledPostsController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user, only: [:create_global_post]
  before_action :set_scheduled_post, only: [:show, :edit, :update, :destroy]

  # GET /scheduled_posts
  # GET /scheduled_posts.json
  def index
    @time = Time.now
    @topics = current_user.topics
    if current_user.admin
      @scheduled_posts = ScheduledPost.all.where.not(topic_id: nil).or(ScheduledPost.where(user_id: current_user.id))
    else
      @scheduled_posts = current_user.scheduled_posts
    end
  end

  def prev_week
    @time = params[:time].to_time.advance( days: -7 ).to_date
    if current_user.admin
      @scheduled_posts = ScheduledPost.all.where.not(topic_id: nil)
    else
      @scheduled_posts = current_user.scheduled_posts
    end
    puts "time_controller: #{@time}"
    respond_to do |format|
      format.html
      format.js
    end
  end

  def next_week
    @time = params[:time].to_time.advance( days: 7 ).to_date
    if current_user.admin
      @scheduled_posts = ScheduledPost.all.where.not(topic_id: nil)
    else
      @scheduled_posts = current_user.scheduled_posts
    end
    puts "time_controller: #{@time}"
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /scheduled_posts/1
  # GET /scheduled_posts/1.json
  def show
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
    puts "global post params: #{params}"
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
    puts "global post params: #{params}"
    screened_params = scheduled_post_params
    failed = false
    succeeded = false
    campaign = Campaign.find(screened_params[:campaign_id])
    platform_types = Account.platform_array.map(&:downcase)

    campaign.microposts.each do |micropost|
      platform = micropost.category.split('_').first
      if platform_types.include?(platform)
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
    succeeded = false
    count = 0

    topic.users.each do |user|
      # do the picture first so you can share the picture across accounts on the same platform
      # check for user overlay
      overlay_id = user.setting.default_overlay_id
      if overlay_id
        overlay = Overlay.find(overlay_id)
        overlay_location = user.setting.default_overlay_location
        if Rails.env.production?
          specs = Overlay.get_specs(overlay_location, overlay.picture.url, micropost.picture.url)
        else
          specs = Overlay.get_specs(overlay_location, overlay.picture.path, micropost.picture.path)
        end
        file_url = Micropost.create_overlay_picture(
          micropost.picture.url,
          overlay,
          specs[0],
          specs[1],
          specs[2],
          specs[3],
          Date.parse(post_date) + 3.months
          )
        if Rails.env.production?
          picture_url = file_url
        else
          picture_url = root_url + file_url
        end
      else
        if Rails.env.production?
          picture_url = micropost.picture.url
        else
          picture_url = root_url + micropost.picture.url
        end
      end

      user.accounts.where(platform: platform.downcase).each do |account|
        count += 1
        post = user.scheduled_posts.build(topic_id: topic_id,
                                          micropost_id: micropost.id,
                                          account_id: account.id,
                                          platform: platform,
                                          picture_url: picture_url,
                                          caption: micropost.content,
                                          post_time: post_time)
        puts "POST TIME: #{post_time}"
        if post.save
          succeeded = true
        else
          failed = true
        end
      end

    end

    if succeeded == true && failed == false
      return "success"
    elsif count == 0
      return "no accounts to post to"
    else
      return "failed"
    end
  end

  # GET /scheduled_posts/1/edit
  def edit
  end

  # POST /scheduled_posts
  # POST /scheduled_posts.json
  def create
    @scheduled_post = ScheduledPost.new(scheduled_post_params)

    if @scheduled_post.save
      flash[:success] = "Post scheduled"
    else
      flash[:danger] = "unable to schedule post"
    end

    redirect_to scheduled_posts_path
  end

  # PATCH/PUT /scheduled_posts/1
  # PATCH/PUT /scheduled_posts/1.json
  def update
    respond_to do |format|
      if @scheduled_post.update(scheduled_post_params)
        format.html { redirect_to @scheduled_post, notice: 'Scheduled post was successfully updated.' }
        format.json { render :show, status: :ok, location: @scheduled_post }
      else
        format.html { render :edit }
        format.json { render json: @scheduled_post.errors, status: :unprocessable_entity }
      end
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
      params.permit( :topic_id, :platform, :picture_url, :micropost_id, :campaign_id, :post_time )
    end

    def admin_user
      if current_user.admin != true
        render status: :forbidden
      end
    end

end

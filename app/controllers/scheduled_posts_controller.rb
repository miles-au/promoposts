class ScheduledPostsController < ApplicationController
  before_action :logged_in_user
  before_action :set_scheduled_post, only: [:show, :edit, :update, :destroy]

  # GET /scheduled_posts
  # GET /scheduled_posts.json
  def index
    @time = Time.now
    @user_posts = current_user.scheduled_posts
  end

  def prev_week
    @time = params[:time].to_time.advance( days: -7 ).to_date
    @user_posts = current_user.scheduled_posts
    puts "time_controller: #{@time}"
    respond_to do |format|
      format.html
      format.js
    end
  end

  def next_week
    @time = params[:time].to_time.advance( days: 7 ).to_date
    @user_posts = current_user.scheduled_posts
    puts "time_controller: #{@time}"
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /scheduled_posts/1
  # GET /scheduled_posts/1.json
  def show
  end

  # GET /scheduled_posts/new
  def new
    @scheduled_post = ScheduledPost.new
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
      params.require(:scheduled_post).permit(:picture_url, :caption, :post_time)
    end
end

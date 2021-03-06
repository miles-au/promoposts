class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers, :settings, :update_settings]
  before_action :correct_user,   only: [:edit, :update, :settings, :update_settings]
  before_action :admin_user,     only: [:index]
  before_action :correct_or_admin_user,   only: [:destroy]
  before_action :logged_out_user, only: [:new]

  protect_from_forgery with: :exception

  def new
    @user = User.new
  end

  def index
    @search = ActiveRecord::Base::sanitize_sql(params[:search])
    if @search
      @users = User.find_user(@search).paginate(:page => params[:page], :per_page => 60)
    else
      @users = User.where(activated: true).order(created_at: :desc).paginate(:page => params[:page], :per_page => 60)
    end    
  end

  def show
    @user = User.find_by_slug(params[:id]) || User.find(params[:id])
    @feed_type = params[:feed] || "digital_assets"

    if @feed_type
      case @feed_type
        when 'digital_assets'
          @feed_items = @user.microposts.paginate(:page => params[:page], :per_page => Micropost.per_page)

        when 'campaign'
          @feed_items = @user.campaigns.all.reverse.paginate(:page => params[:page], :per_page => Micropost.per_page)

        else
          @feed_items = @user.microposts.where(:category => params[:feed]).paginate(:page => params[:page], :per_page => Micropost.per_page)
      end
    else
      @feed_items = @user.microposts.paginate(:page => params[:page], :per_page => Micropost.per_page)
    end

    redirect_to root_url and return unless @user.activated == true

    respond_to do |format|
      format.html
      format.js { render '/shared/feed.js.erb' }
    end

  end

  def create
    @user = User.new(user_params)

    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    oldEmail = @user.email
    newEmail = params[:user][:email]

    if params[:user][:email].empty?
      params[:user][:email] = @user.email
    end

    if @user.update_attributes(user_params)
      if oldEmail != @user.email
        @user.email = oldEmail
        @user.save
        @user.send_verify_email(newEmail)
        flash[:success] = "Profile updated, please check your email to verify your email address."
        redirect_to edit_user_path(@user)
      else
        flash[:success] = "Profile updated"
        redirect_to edit_user_path(@user)
      end
    else
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy!
    flash[:success] = "User deleted"
    if current_user.admin
      redirect_to users_path
    else
      log_out
      redirect_to root_url
    end
    
  end

  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  def settings
    @user = User.find(params[:id])
    @setting = @user.setting
  end

  def unsubscribe_email
    @user = User.find(params[:id])
    @email = @user.email
    @digest = params[:code]

    if @digest != @user.activation_digest
      flash[:danger] = "Invalid unsubscribe link"
      redirect_to root_url
    end
  end

  def unsubscribe_email_action
    puts "PARAMS: #{params}"
    user = User.find(params[:id])
    @email = user.email
    digest = params[:code]

    if digest != user.activation_digest
      flash[:danger] = "Invalid unsubscribe link"
    else
      @settings = user.setting
      @settings.email_for_replies = false
      @settings.email_when_followed = false
      @settings.email_when_new_question = false
      @settings.save!
      flash[:success] = "#{@email} has been unsubscribed from email notifications."
    end

    redirect_to root_url
  end

  def update_timezone
    user = User.find(params[:id])

    #get offsets
    old_timezone_offset = TZInfo::Timezone.get(user.timezone).current_period.utc_total_offset
    new_timezone_offset = TZInfo::Timezone.get(params[:timezone]).current_period.utc_total_offset

    #update offset difference
    difference = new_timezone_offset - old_timezone_offset
    current_user.scheduled_posts.each do |post|
      post.post_time = post.post_time + difference unless post.account_id == nil
      post.save
    end

    user.timezone = params[:timezone]
    if user.save
      flash[:success] = "Updated timezone."
    else
      flash[:danger] = "Unable to update timezone."
    end

    redirect_to accounts_edit_path
  end

  private

    def user_params
      params.require(:user).permit(:name, :company, :email, :password,
                                   :password_confirmation, :category, :picture, :cover_photo, :verify_email, :slug, :timezone, :website, :color)
    end

    # Before filters

    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      if !current_user?(@user)
        message = "currently logged in as #{current_user.name}. Not you? "
        message += "#{view_context.link_to('Log out.', log_out)}".html_safe
        flash[:warning] = message
        redirect_to(root_url)
      end
    end

    # Confirms an admin user.
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

    def correct_or_admin_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user) || current_user.admin?
    end

end

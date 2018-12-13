class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers, :settings, :update_settings]
  before_action :correct_user,   only: [:edit, :update, :settings, :update_settings]
  #before_action :admin_user,     only: [:destroy]
  before_action :correct_or_admin_user,   only: [:destroy]
  before_action :logged_out_user, only: [:new]

  def new
    @user = User.new
  end

  def index
    @search = params[:search]

    if @search

      @users = User.search(@search).paginate(:page => params[:page], :per_page => 20)

    else
      
      @users = User.where(activated: true).order(created_at: :desc).paginate(:page => params[:page], :per_page => 20)
    end
    
  end

  def show
    @user = User.find_by_slug(params[:id]) || User.find(params[:id])
    activity  = Event.where("user_id = :user_id", user_id: @user.id)
    @events = activity.paginate(page: params[:page], :per_page => 10)
    #@microposts = @user.microposts.paginate(page: params[:page], :per_page => 10)
    @products = Product.where("user_id = :user_id", user_id: @user.id)
    redirect_to root_url and return unless @user.activated == true
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
        redirect_to @user
      else
        flash[:success] = "Profile updated"
        redirect_to @user
      end
    else
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy!
    log_out
    flash[:success] = "User deleted"
    redirect_to root_url
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

  def add_product
    @product = Product.new
    respond_to do |format| 
        format.html
        format.js
    end
  end

  def submit_product
    #puts "PARAMS: #{params}"
    product_id = params['product']['product_id']
    user = User.find(params['user_id'])
    title = params['product']['title']
    url = params['product']['url']
    picture = params['product']['picture']

    #if product_id exists
    if product_id
      product = Product.find(product_id)
      product.title = title
      product.url = url
      product.picture = picture
      product.save!
    #else
    else
      product = Product.new(:user_id => user.id, :title => title, :url => url, :picture => picture)
      product.save!
    end
    
    redirect_to user
  end

  def delete_product
    product = Product.find(params['product_id'])
    product.destroy!
    redirect_to current_user
  end

  def settings
    @user = User.find(params[:id])
    @setting = @user.setting
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation, :category, :picture, :cover_photo, :verify_email, :slug)
    end

    # Before filters

    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
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

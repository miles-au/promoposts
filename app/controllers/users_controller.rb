class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers]
  before_action :correct_user,   only: [:edit, :update]
  #before_action :admin_user,     only: [:destroy]
  before_action :correct_or_admin_user,   only: [:destroy]

  def new
    @user = User.new
  end

  def index
    @searchTerm = params['search']
    if @searchTerm
      @users = User.where("activated = ? AND name LIKE ?", true, "#{@searchTerm}%").order(:name).where("name LIKE ?", "#{@searchTerm}%").paginate(:page => params[:page], :per_page => 20)
    else
      @users = User.where(activated: true).order(created_at: :desc).paginate(:page => params[:page], :per_page => 20)
    end
  end

  def show
    @user = User.find(params[:id])
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
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      @user.fb_autoshare
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
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
    puts "PARAMS: #{params}"
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

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation, :category, :picture)
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

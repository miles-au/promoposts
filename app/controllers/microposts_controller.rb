class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_to_facebook,]
  before_action :correct_user,   only: :destroy

  protect_from_forgery except: :show

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.content.blank? && @micropost.picture.url
      @micropost.content = "<image only>"
    end
    if @micropost.save
      flash[:success] = "Your promo post is live!"
      @event = Event.new(active_user_id: current_user.id, micropost_id: @micropost.id)
      redirect_to root_url
    else
      render 'microposts/new'
    end
  end

  def new
    @micropost = current_user.microposts.build
  end

  def destroy
    @micropost.destroy
    flash[:success] = "Promo post deleted"
    redirect_to root_url
  end

  def show
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    respond_to do |format| 
        format.html
        format.js
    end
  end

  def facebook_sharable_pages
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    if @user.oauth_token
      @accounts = @user.facebook.get_connections("me", "accounts")
    else
      #create with facebook and merge accounts
    end
    respond_to do |format| 
        format.html
        format.js { render 'facebook_sharable_pages.js.erb' }
    end
  end

  def share_to_facebook
    #share to facebook
    @accounts = current_user.facebook.get_connection("me", "accounts")
    @micropost = Micropost.find(params['micropost_id'])
    @message = params[:event]['message']
    @pages = params[:event]['pages']

    @accounts.each do |page|
      if @pages.include?(page['id'])
      #if page['id'].to_s == params[:page_id].to_s
        @access_token = page['access_token']
        @page_id = page['id']
        fb_share_helper(@micropost, @page_id, @message, @access_token)
      end
    end

    #share to own page
    @event = Event.new(active_user_id: current_user.id, passive_user_id: @micropost.user.id, micropost_id: @micropost.id)
    @event.save!

    redirect_to root_path
  end

  def fb_share_helper(micropost, page_id, message, access_token)
    fb_page = Koala::Facebook::API.new(access_token)

    if micropost.picture?
      fb_page.put_picture(micropost.picture.path, 'image' ,{:message => message})
    elsif
      fb_page.put_connections(page_id, "feed", :message => message)
    end

    flash[:success] = "Posted to Facebook!"
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :picture)
    end

    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end

end
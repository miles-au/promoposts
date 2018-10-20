class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_to_facebook,]
  before_action :correct_user,   only: :destroy

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.content.blank? && @micropost.picture.url
      @micropost.content = "<image only>"
    end
    if @micropost.save
      flash[:success] = "Your promo post is live!"
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
    @micropost = Micropost.find(params[:id])
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
        format.html { render :action => user_feed }  
        format.js { render 'facebook_sharable_pages.js.erb' }
    end
  end

  def share_to_facebook

    #share to facebook
    @accounts = current_user.facebook.get_connection("me", "accounts")
    @micropost = Micropost.find(params[:post_id])

    @accounts.each do |page|
      if page['id'].to_s == params[:page_id].to_s
        @access_token = page['access_token']
        @page_id = page['id']
      end
    end

    @fb_page = Koala::Facebook::API.new(@access_token)

    if @micropost.picture?
      @fb_page.put_picture(@micropost.picture.path, 'image' ,{:message => @micropost.content})
    elsif
      @fb_page.put_connections(@page_id, "feed", :message => @micropost.content)
    end

    flash[:success] = "Posted to Facebook!"

    #share to own page
    


    redirect_to root_path
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
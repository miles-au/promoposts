class StaticPagesController < ApplicationController
  def home
    if logged_in?
      user_feed
    else
      global_feed
    end
  end

  def global_feed
    @feed_items = Micropost.all.paginate(page: params[:page]) #global feed
    respond_to do |format|
      format.html
      format.js
    end
  end

  def user_feed
    @micropost  = current_user.microposts.build
    @feed_items = current_user.feed.paginate(page: params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def help
  end

  def contact
  end
end

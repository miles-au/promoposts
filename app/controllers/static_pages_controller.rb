class StaticPagesController < ApplicationController

  def home
    if logged_in?
      @micropost = current_user.microposts.build
      @feed_items = current_user.feed.paginate(:page => params[:page], :per_page => 9)
      respond_to do |format| 
          format.html { render :action => user_feed }  
          format.js { render 'user_feed.js.erb' }
      end
    else
      @feed_items = Micropost.all.paginate(:page => params[:page], :per_page => 9) #global feed
      respond_to do |format| 
          format.html { render :action => global_feed }  
          format.js { render 'global_feed.js.erb' }
      end
    end
  end

  def global_feed
    @feed_items = Micropost.all.paginate(:page => params[:page], :per_page => 9) #global feed
    respond_to do |format|
      format.html
      format.js
    end
  end

  def user_feed
    @feed_items = current_user.feed.paginate(:page => params[:page], :per_page => 9)
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

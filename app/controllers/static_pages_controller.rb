class StaticPagesController < ApplicationController

  def home
=begin
    if logged_in?
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

=end
    @feed_type = params[:feed]
    if @feed_type
      #go to specified feed
      case @feed_type
        when "user"
          if logged_in?
            @feed_items = current_user.feed.paginate(:page => params[:page])
          else
            redirect_to login_path
          end

        when "global"
           @feed_items = Micropost.all.paginate(:page => params[:page])

         when "vendor"
            @feed_items = Micropost.vendors.paginate(:page => params[:page])
      end
    else
      #render defaults
      if logged_in?
        @feed_items = current_user.feed.paginate(:page => params[:page])
        @feed_type = "user"
      else
        @feed_items = Micropost.all.paginate(:page => params[:page])
        @feed_type = "global"
      end
    end

    respond_to do |format|
      format.html
      format.js
    end

  end

=begin
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
=end    

  def help
  end

  def contact
  end

end

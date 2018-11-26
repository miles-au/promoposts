class StaticPagesController < ApplicationController

  def home
    if cookies[:columns]
      @columns = cookies[:columns]
      @boot_columns = 12/@columns.to_i
    else
      cookies[:columns] = "3"
      @columns = cookies[:columns]
      @boot_columns = 12/@columns.to_i
    end

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
          @feed_items = Event.all.paginate(:page => params[:page])

        when "vendor"
          @feed_items = Event.vendors.paginate(:page => params[:page])

        when 'questions'
          @feed_items = Event.questions.paginate(:page => params[:page])

        when 'products_discussion'
          @feed_items = Event.products_discussions.paginate(:page => params[:page])

      end
    else
      #render defaults
      if logged_in?
        @feed_items = current_user.feed.paginate(:page => params[:page])
        @feed_type = "user"
      else
        @feed_items = Event.all.paginate(:page => params[:page])
        @feed_type = "global"
      end
    end
    
    respond_to do |format|
      format.html
      format.js
    end

  end

  def change_grid_view
    @columns = params["columns"]
    cookies[:columns] = @columns
    @boot_columns = 12/@columns.to_i
    respond_to do |format|
      format.html
      format.js
    end
  end

  def help
  end

  def contact
  end

  def what_is_autoshare
  end

end

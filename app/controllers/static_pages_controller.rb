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

        when 'search'
          query = params[:search]

          if Rails.env.production?
            @feed_items = Event.joins(:micropost).where("content ILIKE '%#{query}%'").reorder("content ILIKE '#{query}%' DESC").paginate(:page => params[:page])
          else
            @feed_items = Event.joins(:micropost).where("content LIKE '%#{query}%'").reorder("content LIKE '#{query}%' DESC").paginate(:page => params[:page])
          end 

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

    if current_user
      if current_user.picture.url && current_user.accounts.count > 0 && current_user.microposts.count > 0
        current_user.accolade.newcomer = false
        current_user.accolade.save!
      end
      if current_user.accolade.newcomer
        @newcomer = current_user
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

  def wizard
    @user = current_user
  end

  def decline_wizard
    current_user.accolade.newcomer = false
    current_user.accolade.save!
    respond_to do |format|
      format.html
      format.js { flash.now[:success] = "Yer a wizard, #{current_user.name}." }
    end
  end

  def help
  end

  def contact
  end

  def what_is_autoshare
  end

end

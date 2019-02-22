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
            @feed_items_raw = current_user.feed.paginate(:page => params[:page])
          else
            redirect_to login_path
          end

        when "global"
          @feed_items_raw = Event.all.paginate(:page => params[:page])

        when "vendor"
          @feed_items_raw = Event.vendors.paginate(:page => params[:page])

        when 'questions'
          @feed_items_raw = Event.questions.paginate(:page => params[:page])

        when 'careers'
          @feed_items_raw = Event.careers.paginate(:page => params[:page])

        when 'search'
          query = params[:search]

          if Rails.env.production?
            @feed_items_raw = Event.joins(:micropost).where("content ILIKE '%#{query}%'").reorder("content ILIKE '#{query}%' DESC").paginate(:page => params[:page])
          else
            @feed_items_raw = Event.joins(:micropost).where("content LIKE '%#{query}%'").reorder("content LIKE '#{query}%' DESC").paginate(:page => params[:page])
          end 

      end
    else
      #render defaults
      if logged_in?
        @feed_items_raw = current_user.feed.paginate(:page => params[:page])
        @feed_type = "user"
      else
        @feed_items_raw = Event.all.paginate(:page => params[:page])
        @feed_type = "global"
      end
    end

    @feed_items = condense_feed_items(@feed_items_raw)

    #newcomer accolade
    if current_user
      if current_user.picture.url && current_user.accounts.count > 0 && current_user.microposts.count > 0
        current_user.accolade.newcomer = false
        current_user.accolade.save!
      end
      if current_user.accolade.newcomer
        @newcomer = current_user
      end
    end

    #sponsored posts
    
    respond_to do |format|
      format.html
      format.js
    end

  end

  def condense_feed_items(items)
    if Rails.env.production?
      singles = items.select(:micropost_id, :id).group(:micropost_id, :id).having("count(*) = 1").pluck(:id)
      @multis = items.select(:micropost_id, :id).group(:micropost_id, :id).having("count(*) > 1").pluck(:id)

      duplicates = items.select(:micropost_id).group(:micropost_id).having("count(*) > 1")
      counts_hash = duplicates.select(:user_id).group(:user_id).size
    else
      singles = items.select(:micropost_id).group(:micropost_id).having("count(*) = 1").pluck(:id)
      @multis = items.select(:micropost_id).group(:micropost_id).having("count(*) > 1").pluck(:id)

      duplicates = items.select(:micropost_id).group(:micropost_id).having("count(*) > 1")
      counts_hash = duplicates.select(:user_id).group(:user_id).size
    end

    @event_counts = {}
    counts_hash.each do |key,value|
      if @event_counts.key?(key[0])
        @event_counts[key[0]] = @event_counts[key[0]] + 1
      else
        @event_counts[key[0]] = 1
      end
    end

    feed_items = items.where(:id => singles).or(items.where(:id => @multis))

    return feed_items
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
    @contact = Contact.new(:email => "", :subject => "", :message => "")
  end

  def contacted
    email = params[:contact][:email]
    subject = params[:contact][:subject]
    message = params[:contact][:message]

    puts "PARAMS: #{email}, #{subject}, #{message}"
    @contact = Contact.new(:email => email, :subject => subject, :message => message)
    if @contact.valid?
      @contact.send_mailer(email, subject, message)
      flash[:success] = "Message sent! Thank you for contacting us."
      redirect_to contact_path
    else
      render 'contact'
    end
  end

  def what_is_autoshare
  end

end

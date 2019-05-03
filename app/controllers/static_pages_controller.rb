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
            @feed_items_raw = current_user.feed
            @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)
          else
            redirect_to login_path
          end

        when "global"
          @feed_items_raw = Event.all
          @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)

        when "vendor"
          @feed_items_raw = Event.vendors
          @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)

        when 'digital_assets'
          @feed_items_raw = Event.digital_assets
          @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)

        when 'questions'
          @feed_items_raw = Event.questions
          @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)

        when 'careers'
          @feed_items_raw = Event.careers
          @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)

        when "news"
          @feed_items_raw = Event.news
          @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)

        when 'search'
          query = params[:search]

          if Rails.env.production?
            safe_query = ActiveRecord::Base.connection.quote("#{query}%")
            @feed_items_raw = Event.joins(:micropost).where("content ILIKE ?", "%#{query}%").reorder("content ILIKE #{safe_query} DESC")
            @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)
          else
            safe_query = ActiveRecord::Base.connection.quote("#{query}%")
            @feed_items_raw = Event.joins(:micropost).where("content LIKE ?", "%#{query}%").reorder("content LIKE #{safe_query} DESC")
            @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)
          end 

        else
          redirect_to root_path(:feed => 'global')

      end
    else
      #render defaults
      if logged_in?
        @feed_items_raw = current_user.feed
        @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)
        @feed_type = "user"
      else
        @feed_items_raw = Event.all
        @feed_items = condense_feed_items(@feed_items_raw).paginate(:page => params[:page], :per_page => 24)
        @feed_type = "global"
      end
    end

    

    #newcomer accolade
    if current_user
      if current_user.picture.url && current_user.accounts.count > 0 && current_user.microposts.count > 0
        current_user.accolade.newcomer = false
        current_user.accolade.save!
      end
      if current_user.accolade && current_user.accolade.newcomer
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
=begin
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
=end
  
    #get events
    item_counts = items.select('COUNT(id)', :micropost_id).group(:micropost_id, :created_at).size
    event_ids = []
    @event_counts = {}
    item_counts.each do |key, value|
      event_ids << items.find_by(:micropost => key)
      post_events = items.where(:micropost => key)
      @event_counts[key] = post_events.pluck(:user_id).uniq.count
    end

=begin
    duplicates = items.select(:micropost_id).group(:micropost_id).having("count(*) > 1")
    counts_hash = duplicates.select(:user_id).group(:user_id).size

    @event_counts = {}
    counts_hash.each do |key,value|
      if @event_counts.key?(key[0])
        @event_counts[key[0]] = @event_counts[key[0]] + 1
      else
        @event_counts[key[0]] = 1
      end
    end
=end

    #feed_items = items.where(:id => singles).or(items.where(:id => @multis))
    feed_items = items.where(:id => event_ids)

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

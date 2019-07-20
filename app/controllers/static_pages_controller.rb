class StaticPagesController < ApplicationController
  before_action :admin_user,   only: [:admin_panel, :tracking]

  def home
    @digital_asset_types = ['general_update', 'cover_photo', 'email_banner', 'infographic', 'meme']

    @feed_type = params[:feed]
    if @feed_type
      #go to specified feed
      case @feed_type
        when "user"
          if logged_in?
            #get events by following, or self
            user_feed = current_user.feed
            @feed_items = user_feed.paginate(:page => params[:page], :per_page => 24)
          else
            redirect_to login_path
          end

        when "global"
          @feed_items = Event.all.paginate(:page => params[:page], :per_page => 24)

        when 'digital_assets'
          merged_items = (Campaign.all + Micropost.where(:campaign_id => nil)).sort_by {|obj| obj.created_at}.reverse
          @feed_items = merged_items.paginate(:page => params[:page], :per_page => 24)

        when 'campaign'
          @feed_items = Campaign.all.reverse.paginate(:page => params[:page], :per_page => 24)

        when 'search'
          query = params[:search]

          if Rails.env.production?
            safe_query = ActiveRecord::Base.connection.quote("#{query}%")
            @feed_items = (Micropost.where("content ILIKE ?", "%#{query}%") + Campaign.where("content ILIKE ? OR name ILIKE ?", "%#{query}%", "%#{query}%")).paginate(:page => params[:page], :per_page => 24)
          else
            safe_query = ActiveRecord::Base.connection.quote("#{query}%")
            @feed_items = (Micropost.where("content LIKE ?", "%#{query}%") + Campaign.where("content LIKE ? OR name LIKE ?", "%#{query}%", "%#{query}%")).paginate(:page => params[:page], :per_page => 24)
          end 

        else
          @feed_items = Micropost.where(:category => params[:feed]).paginate(:page => params[:page], :per_page => 24)

      end
      
    else

      #default to digital assets
      merged_items = (Campaign.all + Micropost.where(:campaign_id => nil)).sort_by {|obj| obj.created_at}.reverse
      @feed_items = merged_items.paginate(:page => params[:page], :per_page => 24)
      @feed_type = "digital_assets"

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

  def landing_page
  end

  def admin_panel
    @tracks = Track.all.order(:created_at => :desc).limit(10)
  end

  def tracking
    @tracks = Track.all.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 50)
  end

  private
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

end

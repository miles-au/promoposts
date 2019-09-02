class StaticPagesController < ApplicationController
  before_action :admin_user,   only: [:admin_panel, :tracking]

  def home
    @digital_asset_types = ['general_update', 'cover_photo', 'email_banner', 'infographic', 'meme']

    @feed_type = params[:feed]
    if @feed_type
      #go to specified feed
      case @feed_type
        when 'digital_assets'
          @feed_items = Micropost.all.paginate(:page => params[:page], :per_page => Micropost.per_page)

        when 'campaign'
          @feed_items = Campaign.all.reverse.paginate(:page => params[:page], :per_page => Micropost.per_page)

        when 'search'
          query = params[:search]

          if Rails.env.production?
            safe_query = ActiveRecord::Base.connection.quote("#{query}%")
            @feed_items = Micropost.where("content ILIKE ?", "%#{query}%").paginate(:page => params[:page], :per_page => Micropost.per_page)
          else
            safe_query = ActiveRecord::Base.connection.quote("#{query}%")
            @feed_items = Micropost.where("content LIKE ?", "%#{query}%").paginate(:page => params[:page], :per_page => Micropost.per_page)
          end 

        else
          @feed_items = Micropost.where(:category => params[:feed]).paginate(:page => params[:page], :per_page => Micropost.per_page)

      end
      
    else

      #default to digital assets
      @feed_items = Micropost.all.paginate(:page => params[:page], :per_page => Micropost.per_page)
      @feed_type = "digital_assets"

    end

    #sponsored posts to be done
    
    respond_to do |format|
      format.html
      format.js { render '/shared/feed.js.erb' }
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

  def admin_panel
    @topshares = Micropost.all.reorder(:shares => :desc).limit(5)
    @topdownloads = Micropost.all.reorder(:downloads => :desc).limit(5)
    @tracks = Track.all.order(:created_at => :desc).limit(10)
  end

  def tracking
    @tracks = Track.all.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 50)
  end

  def how_does_it_work
    
  end

  private
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

end

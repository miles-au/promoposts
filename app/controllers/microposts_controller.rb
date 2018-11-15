class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_to_facebook,]
  before_action :correct_user,   only: :destroy

  protect_from_forgery except: :show

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.content.blank? && @micropost.picture.url
      @micropost.content = "<image only>"
    end
    if @micropost.save
      flash[:success] = "Your promo post is live!"
      @event = Event.new(user_id: current_user.id, micropost_id: @micropost.id)
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

  def view
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    respond_to do |format| 
        format.html
        format.js
    end
    
  end

  def show
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    @user = @micropost.user
  end

  def share_to_socials
    @user = current_user
    micropost = Micropost.find(params['micropost_id'])
    message = params[:event]['message']
    pages = params[:event]['pages']
    accounts = Account.where('account_id IN (?)', pages)
    buffer_profiles = []
    post_to_providers = []

    accounts.each do |page|
      post_to_providers << page.provider
      case page.provider
        when "facebook"
          share_to_facebook(micropost, page.account_id, message, page.access_token)
        when "linkedin"
          share_to_linkedin(micropost, page.account_id, message, page.access_token)
        when "instagram"
          share_to_instagram(micropost, page.account_id, message, page.access_token)
        when "buffer"
          buffer_profiles.push(page.account_id)
      end
    end

    if !buffer_profiles.empty?
      share_to_buffer(micropost, buffer_profiles, message)
    end

    #create event
    @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id)
    @event.save!

    #create flash message
    post_to_providers = post_to_providers.uniq
    provider_map = post_to_providers.map(&:inspect).join(', ')
    provider_string = provider_map.gsub!('"', '')
    flash[:success] = "Posted to: #{provider_string}"

    redirect_to root_path
  end

  def facebook_sharable_pages
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    if @user.fb_oauth_token
      @accounts = Account.where(:provider => "facebook", :user_id => @user.id)
    else
      #create with facebook and merge accounts
    end
    respond_to do |format| 
        format.html
        format.js { render 'facebook_sharable_pages.js.erb' }
    end
  end

  def share_to_facebook(micropost, page_id, message, access_token)
    #get permissions
    permissions = @user.facebook.get_connections('me', 'permissions')

    fb_page = Koala::Facebook::API.new(access_token)

    if micropost.picture?
      fb_page.put_picture(micropost.picture.path, 'image' ,{:message => message})
    else
      fb_page.put_connections(page_id, "feed", :message => message)
    end
  end

  def linkedin_sharable_pages
    puts "linkedin_sharable_pages"
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    puts "USER: #{@user}"
    if @user.linkedin_oauth_token
      puts "linkedin_oauth_token"
      client = @user.linkedin
      @accounts = Account.where(:provider => "linkedin", :user_id => @user.id)
    else
      #create with facebook and merge accounts
    end
    respond_to do |format| 
        format.html
        format.js { render 'linkedin_sharable_pages.js.erb' }
    end
  end

  def share_to_linkedin(micropost, page_id, message, access_token)
    #get permissions

    client = @user.linkedin

    if micropost.picture.url
      response = client.add_company_share( page_id, :content => {:'title' => message, :'submitted-url' => micropost.picture.url})
    else
      response = client.add_company_share( page_id, :comment => message)
    end
    
    puts "RESPONSE: #{response}"
  end

=begin
  def instagram_sharable_pages
    puts "instagram_sharable_pages"
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    puts "USER: #{@user}"
    if @user.instagram_oauth_token
      puts "instagram_oauth_token"
      client = @user.instagram
      @account = client
    else
      #create with facebook and merge accounts
    end
    respond_to do |format| 
        format.html
        format.js { render 'instagram_sharable_pages.js.erb' }
    end
  end

  def share_to_instagram(micropost, page_id, message, access_token)
    #get permissions

    client = @user.instagram
    picture = root_url + micropost.picture.url

    if micropost.picture?
      response = client.add_company_share( page_id, :content => {:title => message, :'submitted-url' => picture})
    else
      response = client.add_company_share( page_id, :comment => message)
    end
    
    puts "RESPONSE: #{response}"

    #share to own page

    @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id)
    @event.save!

    flash[:success] = "Posted to Instagram!"

    redirect_to root_path
  end
=end


  def buffer_sharable_pages
    puts "buffer_sharable_pages"
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    puts "USER: #{@user}"
    if @user.buffer_oauth_token
      puts "buffer_oauth_token"
      client = @user.buffer
      @accounts = Account.where(:provider => "buffer", :user_id => @user.id)
    else
      #create with facebook and merge accounts
    end
    respond_to do |format| 
        format.html
        format.js { render 'buffer_sharable_pages.js.erb' }
    end
  end

  def share_to_buffer(micropost, profiles, message)
    #get permissions

    client = @user.buffer
    
    if micropost.picture.url
      picture = root_url + micropost.picture.url
      debugger
      response = client.create_update(:body => {:profile_ids => profiles, :text => message, :now => true, :media => {:photo => picture}})
    else
      response = client.create_update(:body => {:profile_ids => profiles, :text => message, :now => true} )
    end
    
    puts "RESPONSE: #{response}"
  end

  def generate_url(url, params = {})
    uri = URI(url)
    uri.query = params.to_query
    uri.to_s
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
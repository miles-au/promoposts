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

  def show
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    respond_to do |format| 
        format.html
        format.js
    end
    
    #linkedin url
    @linkedin_url = generate_url('https://www.linkedin.com/oauth/v2/authorization', "response_type" => "code", "client_id" => ENV['LINKEDIN_CLIENT_ID'], "redirect_uri" => "https://defae573.ngrok.io/auth/linkedin/callback", "state" => ENV['STATE'], "scope" => "r_basicprofile rw_company_admin" )
    
  end

  def share_to_socials
    @user = current_user
    micropost = Micropost.find(params['micropost_id'])
    message = params[:event]['message']
    pages = params[:event]['pages']
    accounts = Account.where('account_id IN (?)', pages)

    accounts.each do |page|
      case page.provider
        when "facebook"
          share_to_facebook(micropost, page.account_id, message, page.access_token)
        when "linkedin"
          share_to_linkedin(micropost, page.account_id, message, page.access_token)
      end
    end
  end

  def facebook_sharable_pages
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    if @user.fb_oauth_token
      @accounts = @user.facebook.get_connections("me", "accounts")
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

    #share to own page

    @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id)
    @event.save!

    flash[:success] = "Posted to Facebook!"

    redirect_to root_path
  end

  def linkedin_sharable_pages
    puts "linkedin_sharable_pages"
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    puts "USER: #{@user}"
    if @user.linkedin_oauth_token
      puts "linkedin_oauth_token"
      client = @user.linkedin
      @accounts = client.company(is_admin: 'true').all
    else
      #create with facebook and merge accounts
    end
    respond_to do |format| 
        format.html
        format.js { render 'linkedin_sharable_pages.js.erb' }
    end
  end

  def share_to_linkedin(micropost, page_id, message, access_token)
    client = @user.linkedin

    if micropost.picture?
      response = client.add_company_share( page_id, :content => {:description => message, :'submitted-image-url' => micropost.picture.path})
    else
      response = client.add_company_share( page_id, :comment => message)
    end
    
    puts "RESPONSE: #{response}"

    #share to own page

    @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id)
    @event.save!

    flash[:success] = "Posted to LinkedIn!"

    redirect_to root_path
  end

  def merge_linkedin
    #send get request

=begin
    link = "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=#{ENV['LINKEDIN_CLIENT_ID']}&redirect_uri=https://defae573.ngrok.io/auth/linkedin/callback&state=#{ENV['STATE']}&scope=r_basicprofile rw_company_admin"
    url = URI.parse(link)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    puts res.body
=end

    get_url = URI('https://www.linkedin.com/oauth/v2/authorization')
    get_params = { "response_type" => "code", "client_id" => ENV['LINKEDIN_CLIENT_ID'], "redirect_uri" => "https://defae573.ngrok.io/auth/linkedin/callback", "state" => ENV['STATE'], "scope" => "r_basicprofile rw_company_admin" }
    get_url.query = URI.encode_www_form(get_params)
    y = Net::HTTP::Get.new(get_url)
    puts "GET: #{Net::HTTP.get(get_url)}"
    puts("URL: #{get_url}")
    puts("LINKEDIN")
    puts y.body # if y.is_a?(Net::HTTPSuccess)

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
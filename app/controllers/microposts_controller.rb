class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_to_facebook]
  before_action :correct_user,   only: :destroy

  protect_from_forgery except: :show

  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'json'

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.content.blank? && @micropost.picture.url
      @micropost.content = "<image only>"
    end
    if @micropost.save
      flash[:success] = "Your promo post is live!"
      @event = Event.new(user_id: current_user.id, micropost_id: @micropost.id)
      if @micropost.category == 'question'
        question_notification_emails
      end
      redirect_to root_url
    else
      render 'microposts/new'
    end
  end

  def question_notification_emails
    @users = User.joins(:setting).where("email_when_new_question = ?", true)
    @users.each do |user|
      if user != @micropost.user
        user.send_community_question_email(@micropost)
      end
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

    if logged_in?
      @fbaccounts = Account.where(:provider => "facebook", :user_id => current_user.id)
      @linkedinaccounts = Account.where(:provider => "linkedin", :user_id => current_user.id)
      @bufferaccounts = Account.where(:provider => "buffer", :user_id => current_user.id)
    end

    respond_to do |format| 
        format.html
        format.js
    end
  end

  def show
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    @comment = Comment.new
    @comments = Comment.where(:micropost_id => @micropost.id, :head => nil)
    @comments = @comments.all.sort_by {|x| x.points }.reverse
    @user = @micropost.user

    if logged_in?
      @fbaccounts = Account.where(:provider => "facebook", :user_id => current_user.id)
      @linkedinaccounts = Account.where(:provider => "linkedin", :user_id => current_user.id)
      @bufferaccounts = Account.where(:provider => "buffer", :user_id => current_user.id)
    end
  end

  def share_to_socials
    @user = current_user
    micropost = Micropost.find(params['micropost_id'])
    message = params[:event]['message']
    pages = params[:event]['pages']
    accounts = Account.where('account_id IN (?)', pages)
    buffer_profiles = []
    @post_success = []
    @post_failure = []

    accounts.each do |page|
      case page.provider
        when "facebook"
          share_to_facebook(micropost, page.account_id, message, Account.get_token(page.access_token))
        when "linkedin"
          share_to_linkedin(micropost, page.account_id, message)
        when "instagram"
          share_to_instagram(micropost, page.account_id, message, Account.get_token(page.access_token))
        when "buffer"
          buffer_profiles.push(page.account_id)
      end
    end

    if !buffer_profiles.empty?
      share_to_buffer(micropost, buffer_profiles, message)
    end

    #create event
    @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id, contribution: 'share')
    @event.save!

    #create notification
    @notification = Notification.new(:user_id => micropost.user_id, :message => "#{@user.name} shared your post.", :url => micropost_url(micropost) )
    @notification.save!


    #create flash message
    @post_success = @post_success.uniq
    @post_failure = @post_failure.uniq

    #if post success includes buffer
    if @post_success.include? 'Buffer'
      
    end

    success_map = @post_success.map(&:inspect).join(', ')
    failure_map = @post_failure.map(&:inspect).join(', ')
    provider_string = success_map.gsub!('"', '')
    fail_string = failure_map.gsub!('"', '')
    puts "POST_SUCCESS: #{@post_success}"

    if @post_failure.empty? && @post_success.empty?
      flash[:warning] = "No posts"
    elsif @post_failure.empty?
      if @post_success.include?('Buffer')
        flash_text = "Posted to: #{provider_string} | #{view_context.link_to('Click here to open Buffer.', 'https://buffer.com', target: '_blank')}".html_safe
        flash[:success] = flash_text
      else
        flash[:success] = "Posted to: #{provider_string}"
      end
    else
      if @post_success.include?('buffer')
        flash_text = "Posted to: #{provider_string} | Failed post: #{fail_string} | #{view_context.link_to('Click here to open Buffer.', 'https://buffer.com')}".html_safe
        flash[:success] = flash_text
      else
        flash[:success] = "Posted to: #{provider_string} | Failed posts: #{fail_string}"
      end
    end



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

    #did the post succeed?
    @post_success << 'Facebook'
  end

  def linkedin_sharable_pages
    #puts "linkedin_sharable_pages"
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    #puts "USER: #{@user}"
    if @user.linkedin_oauth_token
      #puts "linkedin_oauth_token"
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

  def share_to_linkedin(micropost, page_id, message)

    client = @user.linkedin
    accounts = client.company(is_admin: 'true').all.pluck(:id)

    #is this a profile or company page?
    if accounts.include?(page_id)
      uri = URI("https://api.linkedin.com/v1/companies/#{page_id}/shares?format=json")
    else
      uri = URI("https://api.linkedin.com/v1/people/~/shares?format=json")
    end

    token = User.get_token(current_user.linkedin_oauth_token).token

    if micropost.picture.url
      share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, visibility: {code: "anyone"} }.to_json
    else
      share = {comment: message, visibility: {code: "anyone"} }.to_json
    end

    header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{token}" }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    #req = Net::HTTP::Post.new(uri.path, :initheader => { Host: 'api.linkedin.com', Connection: 'Keep-Alive', Authorization: "Bearer #{token}"})
    req = Net::HTTP::Post.new(uri.path, header)
    req.body = share
    res = http.request(req)
    puts "RESPONSE: #{res.body}"
    puts "Response #{res.code} #{res.message}: #{res.body}"
    update = res.body['update']
    
    if update
      @post_success << 'LinkedIn'
    else
      @post_failure << 'LinkedIn'
    end

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
    #puts "buffer_sharable_pages"
    @user = User.find(params[:id])
    @micropost = Micropost.find(params[:micropost])
    #puts "USER: #{@user}"
    if @user.buffer_oauth_token
      #puts "buffer_oauth_token"
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
    
    #puts "RESPONSE: #{response}"
    @post_success << 'Buffer'
  end

  def generate_url(url, params = {})
    uri = URI(url)
    uri.query = params.to_query
    uri.to_s
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :picture, :category, :shareable)
    end

    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end

end
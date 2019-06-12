class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :new, :share_to_socials]
  before_action :correct_or_admin_user, only: [:destroy]

  protect_from_forgery with: :exception

  require 'uri'
  require 'open-uri'
  require 'net/http'
  require 'net/https'
  require 'json'

  rescue_from Koala::Facebook::APIError do |exception|
    if exception.fb_error_code == 190 || exception.fb_error_type == 200
      flash[:danger] = "We were unable to get the required permissions"
    elsif exception.fb_error_code == 32
      flash[:danger] = "Thanks for the enthusiasm! Unfortunately you are making too many requests."
    elsif exception.fb_error_code == 506
      flash[:danger] = "It looks like you've shared this post recently!"
    else
      flash[:danger] = "Sorry, something went wrong."
    end
    redirect_back(fallback_location: root_path)
  end

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.content.blank? && @micropost.picture.url
      @micropost.content = "<image only>"
    end
    if @micropost.save
      flash[:success] = "Your promo post is live!"
      if @micropost.category == 'question'
        question_notification_emails
      end
      if @micropost.campaign_id
        redirect_to campaign_path(id: @micropost.campaign_id)
      else
        redirect_to @micropost
      end
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

=begin
  def view
    @event = Event.new
    @micropost = Micropost.find(params[:id])

    if logged_in?
      @fbaccounts = current_user.accounts.where(:provider => "facebook", :user_id => current_user.id)
      @linkedinaccounts = current_user.accounts.where(:provider => "linkedin", :user_id => current_user.id)
      @bufferaccounts = current_user.accounts.where(:provider => "buffer", :user_id => current_user.id)
    end

    respond_to do |format| 
        format.html
        format.js
    end
  end
=end

  def show
    @event = Event.new
    @micropost = Micropost.find(params[:id])
    if @micropost.campaign_id
      @campaign = Campaign.find(@micropost.campaign_id)
    end
    @comment = Comment.new
    @comments = Comment.where(:micropost_id => @micropost.id, :head => nil)
    @comments = @comments.all.order(created_at: :desc).sort_by {|x| x.points }.reverse
    @user = @micropost.user
    @token = SecureRandom.urlsafe_base64

    if logged_in? && @micropost.shareable
      #current_user.activation_digest = @token
      #current_user.save
      platform_accounts = current_user.accounts
      @fbaccounts = platform_accounts.where(:provider => "facebook", :user_id => current_user.id)
      @linkedinaccounts = platform_accounts.where(:provider => "linkedin", :user_id => current_user.id)
      @bufferaccounts = platform_accounts.where(:provider => "buffer", :user_id => current_user.id)
    end
  end

  def share_to_socials
    @user = current_user
    #if params['token'] != @user.activation_digest
      #head :forbidden
    #end
    micropost = Micropost.find(params['micropost_id'])
    message = params[:event]['message']
    pages = params[:event]['pages']
    accounts = @user.accounts.where('account_id IN (?)', pages)
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

      page.last_share_time = Time.now
      page.save
    end

    if !buffer_profiles.empty?
      share_to_buffer(micropost, buffer_profiles, message)
    end

    if current_user != micropost.user
      #create event
      @event = Event.new(user_id: current_user.id, passive_user_id: micropost.user.id, micropost_id: micropost.id, contribution: 'share')
      @event.save!

      #create notification
      @notification = Notification.new(:user_id => micropost.user_id, :message => "#{@user.name} shared your post.", :category => "share", :destination_id => micropost.id )
      @notification.save!
    end 


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
        if micropost.shares
          micropost.shares += 1
        else 
          micropost.shares = 1
        end
        flash[:success] = "Posted to: #{provider_string} | Failed posts: #{fail_string}"
      end
    end

    redirect_to micropost
  end

=begin
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
=end

  def share_to_facebook(micropost, page_id, message, access_token)

    fb_page = Koala::Facebook::API.new(access_token)

    if micropost.picture?
      if micropost.external_url?
        graph_post = fb_page.put_picture(micropost.picture.url, 'image' ,{:message => message, :link => micropost.external_url})
      else
        graph_post = fb_page.put_picture(micropost.picture.url, 'image' ,{:message => message})
      end
    else
      if micropost.external_url?
        graph_post = fb_page.put_connections(page_id, "feed", :message => message, :link => micropost.external_url)
      else
        graph_post = fb_page.put_connections(page_id, "feed", :message => message)
      end
    end

    @post_success << 'Facebook'
  end

=begin
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
=end

  def share_to_linkedin(micropost, page_id, message)

    client = @user.linkedin
    decrypted_token = User.get_token(current_user.linkedin_oauth_token)

    #create share
    if micropost.picture.url
      if Rails.env.production? 
        pic_url = micropost.picture.url
      else
        pic_url = "#{request.protocol}#{request.subdomain}.#{request.domain}#{micropost.picture.url}"
      end

      if micropost.external_url
        #article with picture
        share = {
            "content": {
                "contentEntities": [
                    {
                        "entityLocation": micropost.external_url,
                        "thumbnails": [
                            { 
                                "imageSpecificContent": {},
                                "resolvedUrl": pic_url
                            }
                        ]
                    }
                ],
                "title": message,
                "shareMediaCategory": "ARTICLE"
            },
            "owner": "urn:li:person:#{page_id}",
        }.to_json
        #share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, :'submitted-url' => micropost.external_url}.to_json
      else
        #picture
=begin AWAITING APPROVAL FOR RICH MEDIA SHARES
        if Rails.env.production?
          pic_upload = RestClient.post('https://api.linkedin.com/media/upload', 
            :fileupload => File.new(micropost.picture.url),
            Authorization: "Bearer #{decrypted_token}")
        else
          RestClient.post('https://api.linkedin.com/media/upload', 
            pic_upload = :fileupload => File.new(open("#{request.protocol}#{request.subdomain}.#{request.domain}#{micropost.picture.url}"),
            { Authorization: "Bearer #{decrypted_token}" }))
        end
        puts "PIC_UPLOAD: #{pic_upload}"
=end

        share = {
            "content": {
                "contentEntities": [
                    {
                        "entityLocation": pic_url,
                        "thumbnails": [
                            {
                                "imageSpecificContent": {},
                                "resolvedUrl": pic_url
                            }
                        ]
                    }
                ],
                "title": message
            },
            "owner": "urn:li:person:#{page_id}",
        }.to_json

        puts "SHARE: #{share}"
      end
    else
      #link without picture
      if micropost.external_url
        #share = {:content=>{ :'submitted-url' => micropost.external_url },comment: message, visibility: {code: "anyone"} }.to_json
        share = {
            "content": {
                "contentEntities": [
                    {
                        "entityLocation": micropost.external_url,
                    }
                ],
                "title": message,
                "shareMediaCategory": "ARTICLE"
            },
            "owner": "urn:li:person:#{page_id}",
        }.to_json
      else
        #share = {comment: message, visibility: {code: "anyone"} }.to_json
        share = {
            "owner": "urn:li:person:#{page_id}",
            "text": {
                "text": message
            }
        }.to_json
      end
    end

    decrypted_token = User.get_token(current_user.linkedin_oauth_token)

    #header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{token}" }
    #HTTParty.post("https://api.linkedin.com/v2/organizationalEntityAcls?q=roleAssignee&oauth2_access_token=#{decrypted_token}")

    header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{decrypted_token}" }
    update = HTTParty.post("https://api.linkedin.com/v2/shares", 
    :body => share,
    :headers => header )

    puts "UPDATE: #{update}"
    puts "UPDATE: #{update['created']}"

=begin AWAITING LINKEDIN APPROVAL FOR COMPANY PAGES
    client = @user.linkedin
    accounts = client.company(is_admin: 'true').all.pluck(:id)

    #is this a profile or company page?
    if accounts.include?(page_id.to_i)
      uri = URI("https://api.linkedin.com/v1/companies/#{page_id}/shares?format=json")
    else
      uri = URI("https://api.linkedin.com/v1/people/~/shares?format=json")
    end

    token = User.get_token(current_user.linkedin_oauth_token).token

    if micropost.picture.url
      if micropost.external_url
        share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, :'submitted-url' => micropost.external_url, visibility: {code: "anyone"} }.to_json
      else
        share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, visibility: {code: "anyone"} }.to_json
      end
    else
      if micropost.external_url
        share = {:content=>{ :'submitted-url' => micropost.external_url },comment: message, visibility: {code: "anyone"} }.to_json
      else
        share = {comment: message, visibility: {code: "anyone"} }.to_json
      end
    end

    header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{token}" }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    #req = Net::HTTP::Post.new(uri.path, :initheader => { Host: 'api.linkedin.com', Connection: 'Keep-Alive', Authorization: "Bearer #{token}"})
    req = Net::HTTP::Post.new(uri.path, header)
    req.body = share
    res = http.request(req)
    update = res.body['update']
    
=end

    if update['created']
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

=begin
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
=end

  def share_to_buffer(micropost, profiles, message)
    #get permissions

    client = @user.buffer
    
    if micropost.picture.url
      if micropost.external_url
        picture = root_url + micropost.picture.url
        response = client.create_update(:body => {:profile_ids => profiles, :text => message, :now => true, :media => {:photo => picture, :link => micropost.external_url}})
      else
        picture = root_url + micropost.picture.url
        response = client.create_update(:body => {:profile_ids => profiles, :text => message, :now => true, :media => {:photo => picture}})
      end
    else
      if micropost.external_url
        response = client.create_update(:body => {:profile_ids => profiles, :text => message, :now => true, :media => {:link => micropost.external_url}} )
      else
        response = client.create_update(:body => {:profile_ids => profiles, :text => message, :now => true} )
      end
    end
    
    #puts "RESPONSE: #{response}"
    @post_success << 'Buffer'
  end

  def generate_url(url, params = {})
    uri = URI(url)
    uri.query = params.to_query
    uri.to_s
  end

  def mark_top_comment
    micropost = Micropost.find(params['micropost_id'])
    micropost.top_comment = params['comment_id']
    micropost.save

    flash[:success] = "Thank you for marking a top comment!"
    redirect_to micropost
  end

  def download_picture
    micropost = Micropost.find(params[:id])
    category = micropost.category || "picture"
    if current_user != micropost.user
      if micropost.downloads
        micropost.downloads += 1
      else 
        micropost.downloads = 1
      end
      micropost.save
    end
    if Rails.env.production?
      send_data(open(micropost.picture.url.read.force_encoding('BINARY')), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
    else
      send_data(open("#{request.protocol}#{request.subdomain}.#{request.domain}#{micropost.picture.url}").read.force_encoding('BINARY'), filename: "#{category} - #{micropost.id}.png", type: 'image/png', disposition: 'attachment')
    end
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :picture, :category, :shareable, :external_url, :campaign_id)
    end

    def correct_or_admin_user
      if current_user.admin == true || current_user.microposts.find_by(id: params[:id])
        @micropost = Micropost.find(params[:id])
      else
        redirect_to root_url
      end
    end

end
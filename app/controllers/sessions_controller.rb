class SessionsController < ApplicationController
  protect_from_forgery except: :oauth2
  protect_from_forgery except: :callback

  before_action :logged_out_user, only: [:new, :social_new]

  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      if user.activated?
      	flash[:success] = "Welcome to Promo Posts, #{user.name}."
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or root_url
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link. "
        message += "#{view_context.link_to('Click here to resend link', sessions_resend_activation_path(email: user.email))}".html_safe
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def callback
    par = request.env['omniauth.params']
    @auth = request.env['omniauth.auth']
    @provider = @auth['provider']
    #@code = params['oauth_verifier']
    #par_code = params['code']

    if par['intent'] == "sign_in"
      #sign_in
      @user = User.create_with_omniauth(@auth)
      if @user
        create_accounts(@provider)
        flash[:success] = "Welcome to Promo Posts, #{@user.name}."
        log_in @user
        remember(@user)
        redirect_back_or root_url
      else
        flash[:danger] = "There was an issue logging you in. We apologize for the inconvenience"
        redirect_back_or root_url
      end
    elsif par['intent'] == "connect"
      #connect
      @user = User.connect_accounts(@auth, current_user.id)
      create_accounts(@provider)
      flash[:success] = "Your #{@provider} account has been connected, #{@user.name}."
      redirect_back_or accounts_edit_path
    else
      puts "Login Error"
      puts "Request: #{request.env['omniauth.params']}"
      flash[:danger] = "There was an error while authenticating your account, we apologize for the inconvenience."
      redirect_back_or root_url
    end

  end

  def oauth2
    provider = params['provider']
    #puts "PROVIDER: #{provider}"

    case provider
      when "linkedin"
        oauth = LinkedIn::OAuth2.new
        url = "#{oauth.auth_code_url}"
        redirect_to url
      when "buffer"
        
      else
        redirect_back_or root_url
    end
  end

  def outh2_callback
    code = params['code']
    provider = params['provider']
    error = params['error'] unless params['error'].nil?
    puts "ERROR: #{error}"

    if error
      flash[:danger] = "There was an error while authenticating your account, we apologize for the inconvenience."
      redirect_to '/accounts/edit'
    else
      if logged_in?
        #already signed in
        #connect with oauth
        @user = User.connect_accounts_oauth2(provider, code, current_user.id)
        create_accounts(provider)
        flash[:success] = "Your #{@provider} account has been connected, #{@user.name}."
        redirect_back_or '/accounts/edit'
      else
        @user = User.create_with_oauth2(provider, code)
        create_accounts(provider)
        log_in @user
        flash[:success] = "Welcome to Promo Posts, #{@user.name}."
        redirect_back_or root_url
      end
    end
    
  end

  def create_accounts(provider)
    case provider
      when "facebook"
        facebook
      when "linkedin"
        linkedin
      when "twitter"
        twitter
      when "instagram"
        instagram
      when "buffer"
        buffer
      when "pinterest"
        pinterest
    end
  end

  def facebook
    @accounts = @user.facebook.get_connection("me", "accounts")

    @accounts.each do |page|
      page_token = @user.facebook.get_page_access_token(page['id'])
      encrypted_token = Account.set_token(page_token)
      picture_url = "https://graph.facebook.com/#{page['id']}/picture"
      if !picture_url
        picture_url = ActionController::Base.helpers.asset_path('page.svg')
      end

      a = Account.find_by(:account_id => page['id'],:user_id => @user.id)
      if a
        a.update(:name => page['name'], :account_id => page['id'] , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => "facebook")
      else
        a = Account.new(:name => page['name'], :account_id => page['id'] , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => "facebook")
        a.save
        a
      end
    end
  end

  def linkedin

=begin LINKEDIN COMPANY PAGES AWAITING TO JOIN PROGRAM
    #check company pages
    @accounts = @user.linkedin_companies

    puts "ACCOUNTS: #{@accounts}"

    if @accounts
      @accounts.each do |page|
        picture_url = client.company(id:"#{page.id}:(id,name,square-logo-url)").square_logo_url
        if !picture_url
          picture_url = ActionController::Base.helpers.asset_path('page.svg')
        end
        a = Account.find_by(:account_id => page.id)
        if a
          a.update(:name => page.name, :account_id => page.id , :provider => "linkedin", :user_id => @user.id, :picture => picture_url)
        else
          a = Account.new(:name => page.name, :account_id => page.id , :provider => "linkedin", :user_id => @user.id, :picture => picture_url)
          a.save
          a
        end
      end
    end
=end
  
    client = @user.linkedin

    #check profile
    picture_url = client['profilePicture']['displayImage~']['elements'].first['identifiers'].first['identifier']
    if !picture_url
      picture_url = ActionController::Base.helpers.asset_path('page.svg')
    end
    profile_id = client['id']
    a = Account.find_by(:account_id => profile_id)
    if a
      a.update(:name => "#{client['firstName']["localized"]["en_US"]} #{client['lastName']["localized"]["en_US"]} | profile", :account_id => profile_id , :provider => "linkedin", :user_id => @user.id, :picture => picture_url, :platform => "linkedin")
    else
      a = Account.new(:name => "#{client['firstName']["localized"]["en_US"]} #{client['lastName']["localized"]["en_US"]} | profile", :account_id => profile_id , :provider => "linkedin", :user_id => @user.id, :picture => picture_url, :platform => "linkedin")
      a.save
      a
    end
  end

  def twitter
    client = @user.twitter
    picture_url = @auth[:extra][:raw_info][:profile_image_url]
    if !picture_url
      picture_url = ActionController::Base.helpers.asset_path('page.svg')
    end
    profile_id = client.user.id
    a = Account.find_by(:account_id => profile_id)
    if a
      a.update(:name => "#{client.user.name} | profile", :account_id => profile_id , :provider => "twitter", :user_id => @user.id, :picture => picture_url, :platform => "twitter")
    else
      a = Account.new(:name => "#{client.user.name} | profile", :account_id => profile_id , :provider => "twitter", :user_id => @user.id, :picture => picture_url, :platform => "twitter")
      a.save
      a
    end
  end

  def instagram
    client = @user.instagram

    a = Account.find_by(:account_id => client.user.id)
    if a
      a.update(:name => client.user.full_name, :account_id => client.user.id , :provider => @provider, :user_id => @user.id, :access_token => @auth.credentials.token, :uid => @auth['uid'], :platform => "instagram")
    else
      a = Account.new(:name => client.user.full_name, :account_id => client.user.id , :provider => @provider, :user_id => @user.id, :access_token => @auth.credentials.token, :uid => @auth['uid'], :platform => "instagram")
        a.save
        a
    end
  end

  def buffer
    client = @user.buffer
    @accounts = client.profiles

    @accounts.each do |page|
      page_token = @auth.credentials.token
      encrypted_token = Account.set_token(page_token)
      if page.service == 'facebook' && page.service_type == 'profile'
        #facebook profiles currently not served
        a = Account.find_by(:account_id => page.id)
        a
      else
        picture_url = client.profile_by_id(page.id).avatar
        if !picture_url
          picture_url = ActionController::Base.helpers.asset_path('page.svg')
        end
        a = Account.find_by(:account_id => page.id)
        if a
          a.update(:name => "#{page.service_username} | #{page.service} - #{page.service_type}", :account_id => page.id , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => page.service )
        else
          a = Account.new(:name => "#{page.service_username} | #{page.service} - #{page.service_type}", :account_id => page.id , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => page.service )
          a.save
          a
        end
      end
    end
  end

  def pinterest
    @boards = @user.pinterest.get_boards.data rescue nil
    return if @boards.nil?

    user_info = @user.pinterest.me.data rescue nil
    return if user_info.nil?

    pic = @user.pinterest.me({fields: "image"})
    picture_url = pic.data.image.first.last.url rescue nil
    return if picture_url.nil?

    @boards.each do |page|
      page_token = @auth.credentials.token
      encrypted_token = Account.set_token(page_token)

      if !picture_url
        picture_url = ActionController::Base.helpers.asset_path('page.svg')
      end
      a = Account.find_by(:account_id => page.id)

      if a
        a.update( :name => "#{user_info.first_name} #{user_info.last_name} | #{page.name}", :account_id => page.id , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => "pinterest" )
      else
        a = Account.new( :name => "#{user_info.first_name} #{user_info.last_name} | #{page.name}", :account_id => page.id , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => "pinterest" )
        a.save
        a
      end

    end

  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  def resend_activation
  	@user = User.find_by_email(params[:email])
    if @user
      @user.resend_activation_email
      flash[:success] = "Activation email resent! You should receive your link shortly."
      redirect_to root_url
    else
      flash[:danger] = 'Email is not associated with any account, please sign up first.'
      redirect_to root_url
    end
  end

end

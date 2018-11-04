class SessionsController < ApplicationController

  def new
    @state = SecureRandom.hex(10)
    @client_id = ENV['LINKEDIN_CLIENT_ID']
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
    @code = params['oauth_verifier']
    puts "STATE: #{par['state']}"

    #verify state

    if par['intent'] == "sign_in"
      #sign_in
      @user = User.create_with_omniauth(@auth)
      create_accounts(@provider)
      log_in @user
      flash[:success] = "Welcome to Promo Posts, #{@user.name}."
      redirect_back_or root_url
    elsif par['intent'] == "connect"
      #connect
      
      create_accounts(@provider)
      redirect_back_or root_url
    else
      flash[:danger] = "We are experiencing technical difficulties, we apologize for the inconvenience."
      redirect_to root_url
    end

  end

  def create_accounts(provider)
    case provider
      when "facebook"
        facebook
      when "linkedin"
        linkedin
      else
        flash[:danger] = "We are experiencing technical difficulties, we apologize for the inconvenience."
        redirect_to root_url
    end
  end

  def facebook
    @accounts = @user.facebook.get_connection("me", "accounts")

    @accounts.each do |page|
      a = Account.find_by(:account_id => page['id'])
      if a
        a
      else
        a = Account.new(:name => page['name'], :account_id => page['id'] , :provider => @provider, :user_id => @user.id, :autoshare => false, :access_token => @auth.credentials.token, :uid => @auth['uid'])
        a.save
        a
      end
    end
  end

  def linkedin
    client = @user.linkedin
    @accounts = client.company(is_admin: 'true').all

    @accounts.each do |page|
      a = Account.find_by(:account_id => page.id)
      if a
        a
      else
        a = Account.new(:name => page.name, :account_id => page.id , :provider => @provider, :user_id => @user.id, :autoshare => false, :access_token => @auth.credentials.token, :uid => @auth['uid'])
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
      flash[:danger] = 'Email is not asociated with any account, please sign up first.'
      redirect_to root_url
    end
  end

end

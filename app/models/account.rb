class Account < ApplicationRecord
  belongs_to :user
  has_many :scheduled_posts, dependent: :destroy

  def self.set_token(val)
  	encrypt_value(val)
  end

  def self.get_token(val)
  	decrypt_value(val)
  end

  def self.platform_array
  	array = ['Facebook', 'LinkedIn', 'Instagram', 'Twitter', 'Pinterest']
  end

  def self.provider_array
  	array = ['Buffer', 'Facebook', 'LinkedIn', 'Twitter']
   #array = ['Buffer', 'Facebook', 'LinkedIn', 'Twitter', 'Pinterest']
  end

  def self.check_account_facebook(user)
  	accounts = user.facebook.get_connection("me", "accounts").pluck("id") rescue []
  end

  def self.check_account_linkedin(current_user)
  	account = [ current_user.linkedin['id'].to_s ] rescue []
  end

  def self.check_account_buffer(user)
  	accounts = user.buffer.profiles.pluck("id") rescue []
  end

  def self.check_account_twitter(current_user)
  	account = [ current_user.twitter.user.id.to_s ] rescue []
  end

  def self.check_account_pinterest(user)
  	boards = user.pinterest.get_boards.data.pluck("id") rescue []
  end

  def self.best_post_time(platform, post_date)
    case platform
      when "facebook"
        post_time = post_date.change({ hour: 13 })
      when "linkedin"
        post_time = post_date.change({ hour: 12 })
      when "twitter"
        post_time = post_date.change({ hour: 14 })
      when "instagram"
        post_time = post_date.change({ hour: 12 })
      when "pinterest"
        post_time = post_date.change({ hour: 21 })
      else
    end
  end

  def self.create_facebook_accounts(user, auth)
    resp = true
    user.facebook.get_connection("me", "accounts").each do |page|
      page_token = user.facebook.get_page_access_token(page['id'])
      encrypted_token = Account.set_token(page_token)
      picture_url = "https://graph.facebook.com/#{page['id']}/picture"
      a = user.accounts.find_or_initialize_by(account_id: page['id'])
      resp = false unless a.update(:name => page['name'], :account_id => page['id'] , :provider => "facebook", :user_id => user.id, :access_token => encrypted_token, :uid => auth['uid'], :picture => picture_url, :platform => "facebook")
    end
    return resp
  end

  def self.create_linkedin_accounts(user, auth)
    resp = true
    client = user.linkedin
    picture_url = client['profilePicture']['displayImage~']['elements'].first['identifiers'].first['identifier']
    a = user.accounts.find_or_initialize_by(:account_id => client['id'])
    resp = false unless a.update(:name => "#{client['firstName']["localized"]["en_US"]} #{client['lastName']["localized"]["en_US"]} | profile", :account_id => client['id'] , :provider => "linkedin", :user_id => user.id, :picture => picture_url, :platform => "linkedin")
    return resp
  end

  def self.create_twitter_accounts(user, auth)
    resp = true
    client = user.twitter
    picture_url = auth[:extra][:raw_info][:profile_image_url]
    a = user.accounts.find_or_initialize_by( :account_id => client.user.id )
    resp = a.update(:name => "#{client.user.name}", :account_id => client.user.id , :provider => "twitter", :user_id => user.id, :picture => picture_url, :platform => "twitter")
    return resp
  end

  def self.create_buffer_accounts(user, auth)
    resp = true
    client = user.buffer
    client.profiles.each do |page|
      encrypted_token = Account.set_token(auth.credentials.token)
      if page.service == 'facebook' && page.service_type == 'profile'
        #facebook profiles currently not served
        a = Account.find_by(:account_id => page.id)
      else
        picture_url = client.profile_by_id(page.id).avatar
        a = user.accounts.find_or_initialize_by( :account_id => page.id )
        resp = false unless a.update(:name => "#{page.service_username} | #{page.service} - #{page.service_type}", :account_id => page.id , :provider => "buffer", :user_id => user.id, :access_token => encrypted_token, :uid => auth['uid'], :picture => picture_url, :platform => page.service )
      end
    end
    return resp
  end

  def self.create_pinterest_accounts(user, auth)
    resp = true
    boards = user.pinterest.get_boards.data rescue nil
    user_info = user.pinterest.me.data rescue nil
    picture_url = user.pinterest.me({fields: "image"}).data.image.first.last.url rescue nil

    boards.each do |page|
      page_token = auth.credentials.token
      encrypted_token = Account.set_token(page_token)
      a = user.accounts.find_or_initialize_by( :account_id => page.id )
      resp = false unless a.update( :name => "#{user_info.first_name} #{user_info.last_name} | #{page.name}", :account_id => page.id , :provider => @provider, :user_id => @user.id, :access_token => encrypted_token, :uid => @auth['uid'], :picture => picture_url, :platform => "pinterest" )
    end
    return resp
  end

  private

	  def self.encrypt_value(val)
	    # salt = ENV['SALT'] # We save the value of: SecureRandom.random_bytes(64)
	    key = [ENV['KEY']].pack('H*')
	    crypt = ActiveSupport::MessageEncryptor.new(key)
	    encrypted_data = crypt.encrypt_and_sign(val)
	    encrypted_data
	  end

	  def self.decrypt_value(val)
	    key = [ENV['KEY']].pack('H*')
	    crypt = ActiveSupport::MessageEncryptor.new(key)
	    decrypted_data = crypt.decrypt_and_verify(val)
	    decrypted_data
	  end
end

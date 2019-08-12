class Account < ApplicationRecord
  belongs_to :user

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

class Account < ApplicationRecord
  belongs_to :user

  def self.set_token(val)
  	encrypt_value(val)
  end

  def self.get_token(val)
  	decrypt_value(val)
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

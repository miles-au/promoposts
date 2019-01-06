class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  has_many :products, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_one :accolade, dependent: :destroy
  has_one :setting, dependent: :destroy

  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  before_create :create_activation_digest
  after_create :set_slug_default
  after_create :create_accolades
  after_create :create_setting


  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  #VALID_SLUG_REGEX = /\A[-\w.]+\z/i
  #validates :slug, format: { with: VALID_SLUG_REGEX }, uniqueness: { case_sensitive: false }, length: { maximum: 75 }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :category, presence: true

  mount_uploader :picture, PictureUploader
  mount_uploader :cover_photo, PictureUploader
  validate  :picture_size

  require 'rubygems'
  #require 'linkedin'

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activates an account.
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # Verify an email.
  def self.verify_email(user_id)
    user = User.find(user_id)
    user.verify_email = true
    user.save
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def resend_activation_email
    create_activation_digest
    UserMailer.account_activation(self).deliver_now
  end

  def send_verify_email(email)
    create_activation_digest
    puts "EMAIL: #{email}"
    UserMailer.verify_email(self, email).deliver_now
  end

  def send_comment_mailer(user, micropost, message, category, commenter)
    UserMailer.comment(user, micropost, message, category, commenter).deliver_now
  end

  def send_followed_email(follower)
    UserMailer.followed_email(self, follower).deliver_now
  end

  def send_community_question_email(micropost)
    UserMailer.community_question_notification(self, micropost).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Returns a user's feed.
  def feed
    following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    #Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
    Event.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
  end

  # Follows a user.
  def follow(other_user)
    following << other_user
  end

  # Unfollows a user.
  def unfollow(other_user)
    following.delete(other_user)
  end

  # Returns true if the current user is following the other user.
  def following?(other_user)
    following.include?(other_user)
  end

  def self.create_with_omniauth(auth)
    #figure out which provider and create user

    encrypted_token = User.encrypt_value(auth.credentials.token)

    #find user by email first
    user = User.find_by(:email => "#{auth['uid']}@#{auth['provider']}.com")

    case auth['provider']
      when "facebook"
        if user
          user.fb_uid = auth['uid']
        else
          user = User.find_or_initialize_by(fb_uid: auth['uid'])
        end
        user.fb_oauth_token = encrypted_token
      when "linkedin"
        if user
          user.linkedin_uid = auth['uid']
        else
          user = User.find_or_initialize_by(linkedin_uid: auth['uid'])
        end
        user.linkedin_oauth_token = encrypted_token
      when "instagram"
        if user
          user.instagram_uid = auth['uid']
        else
          user = User.find_or_initialize_by(instagram_uid: auth['uid'])
        end
        user.instagram_oauth_token = encrypted_token
      when "buffer"
        if user
          user.buffer_uid = auth['uid']
        else
          user = User.find_or_initialize_by(buffer_uid: auth['uid'])
        end
        user.buffer_oauth_token = encrypted_token
        user.name = auth.extra.raw_info.name
    end

    user.password ||= self.new_token
    user.name ||= auth['info']['name']
    user.activated = true
    user.activated_at ||= Time.zone.now
    #user.oauth_token = auth.credentials.token

    #save/return the user
    if user.new_record?
      user.email = "#{auth['uid']}@#{auth['provider']}.com"
      user.category = "none"
    end

    user.save!
    user

  end

  def self.connect_accounts(auth, id)
    #puts "AUTH: #{auth}"

    encrypted_token = User.encrypt_value(auth.credentials.token)

    user = User.find(id)
    case auth['provider']
      when "facebook"
        user.fb_oauth_token = encrypted_token
        user.fb_uid = auth.uid
      when "linkedin"
        user.linkedin_oauth_token = encrypted_token
        #user.linkedin_oauth_secret = auth.credentials.secret
        user.linkedin_uid = auth.uid
      when "instagram"
        user.instagram_oauth_token = encrypted_token
        user.instagram_uid = auth.uid
      when "buffer"
        user.buffer_oauth_token = encrypted_token
        user.buffer_uid = auth.uid
    end
    user.save
    user
  end

  def self.connect_accounts_oauth2(provider, code, id)
    case provider
      when "linkedin"
        oauth = LinkedIn::OAuth2.new
        access_token = oauth.get_access_token(code)
        encrypted_token = User.encrypt_value(access_token)
        api = LinkedIn::API.new(access_token)
        uid = api.profile.id

        user = User.find(id)
        user.linkedin_uid = uid
        user.linkedin_oauth_token = encrypted_token
      when "buffer"
        
    end

    user.save
    user
  end

  def self.create_with_oauth2(provider, code)
    #find user by email first
    #user = User.find_by(:email => "#{auth['uid']}@#{provider}.com")

    case provider
      when "linkedin"
        oauth = LinkedIn::OAuth2.new
        access_token = oauth.get_access_token(code)
        encrypted_token = User.encrypt_value(access_token)
        api = LinkedIn::API.new(access_token)
        uid = api.profile.id

        user = User.find_by(:email => "#{uid}@#{provider}.com")

        if user
          user.linkedin_uid = uid
        else
          user = User.find_or_initialize_by(linkedin_uid: uid)
        end
        user.linkedin_oauth_token = encrypted_token
      when "buffer"

    end

    user.password = self.new_token
    user.name ||= "#{api.profile.first_name} #{api.profile.last_name}"
    user.activated = true
    user.activated_at ||= Time.zone.now
    #user.oauth_token = auth.credentials.token

    #save/return the user
    if user.new_record?
      user.email = "#{uid}@#{provider}.com"
      user.category = "none"
    end

    user.save!
    user
  end

  def facebook
    decrypted_token = User.decrypt_value(self.fb_oauth_token)
    @facebook ||= Koala::Facebook::API.new(decrypted_token)
  end

  def self.unauthorize_facebook(user)
    user.facebook.delete_object("me/permissions")
    user.fb_uid = nil
    user.fb_oauth_token = nil
    user.save!
  end

  def linkedin
    decrypted_token = User.decrypt_value(self.linkedin_oauth_token)
    @linkedin = LinkedIn::API.new(decrypted_token)
  end

  def self.unauthorize_linkedin(user)
    #disconnect linkedin
    user.linkedin_uid = nil
    user.linkedin_oauth_token = nil
    user.save!
  end

  def instagram
    decrypted_token = User.decrypt_value(self.instagram_oauth_token)
    client = Instagram.client(:access_token => decrypted_token)
  end

  def self.unauthorize_instagram
    
  end

  def buffer
    decrypted_token = User.decrypt_value(self.buffer_oauth_token)
    @buffer = Buffer::Client.new(decrypted_token)
  end

  def self.unauthorize_buffer(user)
    #POST https://api.bufferapp.com/1/user/deauthorize.json
    user.buffer_uid = nil
    user.buffer_oauth_token = nil
    user.save!
  end

  def avatar
    if self.picture.url
      self.picture.url
    else
      return "/assets/avatar.png"
    end
  end

  def self.get_token(val)
    decrypt_value(val)
  end

  def self.search(query)

    if Rails.env.production?
      results = User.where("name ILIKE '%#{query}%'").reorder("name ILIKE '#{query}%' DESC")
    else
      results = User.where("name LIKE '%#{query}%'").reorder("name LIKE '#{query}%' DESC ")
    end 
    
    results
  end

  def notifications_today
    notifications = Notification.where( 'user_id = ? AND created_at > ?', self.id, 1.day.ago)
    return notifications
  end

  def unread_notifications
    notifications = Notification.where( 'user_id = ? AND read = ?', self.id, false)
    return notifications
  end

  private

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    # Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
      if new_record?
        return
      else
        update_columns(activation_digest: User.digest(activation_token))
      end   
    end

    def picture_size
      if picture.size > 10.megabytes
        errors.add(:picture, "Profile picture should be less than 10MB")
      end
      if cover_photo.size > 10.megabytes
        errors.add(:picture, "Cover photo should be less than 10MB")
      end
    end

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

    def set_slug_default
      self.slug = self.id
      self.save!
    end

    def create_accolades
      accolades = Accolade.new(user_id: self.id)
      accolades.save!
    end

    def create_setting
      settings = Setting.new(user_id: self.id)
      settings.save!
    end

end

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

  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  before_create :create_activation_digest

  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :category, presence: true

  mount_uploader :picture, PictureUploader
  mount_uploader :cover_photo, PictureUploader
  validate  :picture_size

  require 'rubygems'
  require 'linkedin'


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

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def resend_activation_email
    create_activation_digest
    UserMailer.account_activation(self).deliver_now
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

    #puts "AUTH: #{auth}"

    case auth['provider']
      when "facebook"
        user = User.find_or_initialize_by(fb_uid: auth['uid'])
        user.fb_oauth_token = auth.credentials.token
      when "linkedin"
        user = User.find_or_initialize_by(linkedin_uid: auth['uid'])
        user.linkedin_oauth_token = auth.credentials.token
        #user.linkedin_oauth_secret = auth.credentials.secret
      when "instagram"
        user = User.find_or_initialize_by(instagram_uid: auth['uid'])
        user.instagram_oauth_token = auth.credentials.token
      when "buffer"
        user = User.find_or_initialize_by(buffer_uid: auth['uid'])
        user.buffer_oauth_token = auth.credentials.token
        user.name = auth.extra.raw_info.name
    end

    user.password = self.new_token
    user.name ||= auth['info']['name']
    user.category = "none"
    user.activated = true
    user.activated_at = Time.zone.now
    #user.oauth_token = auth.credentials.token

    #save/return the user
    if user.new_record?
      user.email = "#{auth['uid']}@#{auth['provider']}.com"
      user.save!
      user
    else
      user
    end
  end

  def self.connect_accounts(auth, id)
    #puts "AUTH: #{auth}"

    user = User.find(id)
    case auth['provider']
      when "facebook"
        user.fb_oauth_token = auth.credentials.token
        user.fb_uid = auth.uid
      when "linkedin"
        user.linkedin_oauth_token = auth.credentials.token
        #user.linkedin_oauth_secret = auth.credentials.secret
        user.linkedin_uid = auth.uid
      when "instagram"
        user.instagram_oauth_token = auth.credentials.token
        user.instagram_uid = auth.uid
      when "buffer"
        user.buffer_oauth_token = auth.credentials.token
        user.buffer_uid = auth.uid
    end
    user.save
    user

  end

  def facebook
    #puts "OAUTH: #{fb_oauth_token}"
    @facebook ||= Koala::Facebook::API.new(self.fb_oauth_token)
  end

  def linkedin
    #puts "OAUTH: #{linkedin_oauth_token}"
    #client = LinkedIn::Client.new( self.linkedin_oauth_token, self.linkedin_oauth_secret)
    @linkedin = LinkedIn::Client.new( ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET'])
    @linkedin.authorize_from_access(ENV['LINKED_APP_KEY'])
    @linkedin
  end

  def instagram
    #puts "OAUTH: #{instagram_oauth_token}"
    client = Instagram.client(:access_token => self.instagram_oauth_token)
  end

  def buffer
    #puts "OAUTH: #{buffer_oauth_token}"
    @buffer = Buffer::Client.new(self.buffer_oauth_token)
  end

  def avatar
    if self.picture.url
      self.picture.url
    else
      return "/assets/avatar.png"
    end
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

    def get_oauth_token
    end

end

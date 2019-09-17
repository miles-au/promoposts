class User < ApplicationRecord
  encrypts :email
  blind_index :email

  has_many :microposts, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  has_many :campaigns, dependent: :destroy
  has_many :tracks
  has_many :overlays, dependent: :destroy
  has_many :scheduled_posts, dependent: :destroy
  has_many :followed_topics, class_name:  "TopicRelationship",
                                   foreign_key: "user_id"
  has_many :topics, through: :followed_topics
  has_one :setting, dependent: :destroy

  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :slug, uniqueness: { case_sensitive: false, allow_nil: true }, length: { maximum: 75 }
  after_validation :valid_slug
  VALID_COLOR_REGEX = /\A#(?:[A-F0-9]{6})\z/i
  validates :color, length: { is: 7 }, format: { with: VALID_COLOR_REGEX }
  
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :company, length: { maximum: 50 }
  validates :website, length: { maximum: 50 }
  validate  :picture_size

  before_save   :downcase_email
  before_save :set_timezone_to_utc
  before_create :create_activation_digest
  after_create :create_setting
  after_create :follow_promo_posts

  mount_uploader :picture, PictureUploader
  mount_uploader :cover_photo, PictureUploader

  attr_accessor :remember_token, :activation_token, :reset_token

  has_secure_password

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

  #notification emails
  def send_followed_email(follower)
    if self.verify_email
      UserMailer.followed_email(self, follower).deliver_now
    end
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

  def connect_accounts(auth)
    puts "AUTH: #{auth}"
    encrypted_token = User.encrypt_value(auth.credentials.token)
    case auth['provider']
      when "facebook"
        self.fb_oauth_token = encrypted_token
        self.fb_uid = auth.uid
      when "linkedin"
        self.linkedin_oauth_token = encrypted_token
        self.linkedin_uid = auth.uid
      when "twitter"
        encrypted_token = User.encrypt_value(auth.credentials.secret)
        self.twitter_oauth_token = encrypted_token
        self.twitter_uid = auth.credentials.token
      when "buffer"
        self.buffer_oauth_token = encrypted_token
        self.buffer_uid = auth.uid
      when "pinterest"
        self.pinterest_oauth_token = encrypted_token
        self.pinterest_uid = auth.uid
    end
    if self.save
      puts "SAVED"
      return true
    else
      puts "FAILED TO SAVE"
      return false
    end
  end

  def facebook
    puts "VAL: #{fb_oauth_token}"
    decrypted_token = User.decrypt_value(fb_oauth_token)
    facebook ||= Koala::Facebook::API.new(decrypted_token)
  end

  def unauthorize_facebook
    #user.facebook.delete_object("me/permissions")
    resp = delete_social_accounts("facebook")
    return resp
  end

  def linkedin
    decrypted_token = User.decrypt_value(self.linkedin_oauth_token)
    @linkedin = HTTParty.get("https://api.linkedin.com/v2/me?projection=(id,firstName,lastName,profilePicture(displayImage~:playableStreams))&oauth2_access_token=#{decrypted_token}")
  end

  # def linkedin_companies
  #   decrypted_token = User.decrypt_value(self.linkedin_oauth_token)
  #   @accounts = HTTParty.get("https://api.linkedin.com/v2/organizationalEntityAcls?q=roleAssignee&oauth2_access_token=#{decrypted_token}")
  # end

  def unauthorize_linkedin
    #disconnect linkedin
    resp = delete_social_accounts("linkedin")
    return resp
  end

  def twitter
    decrypted_token = User.decrypt_value(self.twitter_oauth_token)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_KEY"]
      config.consumer_secret     = ENV["TWITTER_SECRET"]
      config.access_token        = self.twitter_uid
      config.access_token_secret = decrypted_token
    end
    @twitter = client
  end

  def unauthorize_twitter
    #disconnect twitter
    resp = delete_social_accounts("twitter")
    return resp
  end

  def pinterest
    decrypted_token = User.decrypt_value(self.pinterest_oauth_token)
    @pinterest = Pinterest::Client.new(decrypted_token)
  end

  def unauthorize_pinterest
    resp = delete_social_accounts("pinterest")
    return resp
  end

  def buffer
    decrypted_token = User.decrypt_value(self.buffer_oauth_token)
    @buffer = Buffer::Client.new(decrypted_token)
  end

  def unauthorize_buffer
    #POST https://api.bufferapp.com/1/user/deauthorize.json
    resp = delete_social_accounts("buffer")
    return resp
  end

  def delete_social_accounts(provider)
    accounts = self.accounts.where(:provider => provider)
    if provider == "facebook"
      provider = "fb"
    end
    self["#{provider}_uid"] = nil
    self["#{provider}_oauth_token"] = nil
    if self.save && accounts.destroy_all
      return true
    else
      return false
    end
  end

  def avatar
    if self.picture.url
      self.picture.url
    else
      return nil
    end
  end

  def self.get_token(val)
    decrypt_value(val)
  end

  def self.find_user(query)
    safe_query = ActiveRecord::Base.connection.quote("#{query}%")
    results = User.where("name LIKE ?", "%#{query}%" ).reorder("name LIKE #{safe_query} DESC ")
  end

  def check_accounts
    providers = self.accounts.pluck("provider").uniq
    accounts = []
    providers.each do |provider|
      accounts += Account.send("check_account_#{provider.downcase}", self)
    end
    return accounts
  end

  def get_picture_with_default_overlay(bg_image, delete_by)
    overlay_id = self.setting.default_overlay_id
    return bg_image unless overlay_id
    overlay = Overlay.find(overlay_id)
    overlay_location = self.setting.default_overlay_location
    specs = Overlay.get_specs(overlay_location, overlay.picture.url, bg_image)
    file_url = Micropost.create_overlay_picture( bg_image, overlay, specs[0], specs[1], specs[2], specs[3], delete_by )
    return file_url  
  end

  # Follows a topic.
  def add_topic(topic)
    topics << topic
    # get scheduled posts from admin

    posts = User.first.scheduled_posts.where("post_time > ? AND topic_id = ?", Time.now.getutc, topic.id)
    posts.each do |post|
      self.accounts.where(platform: post.platform).each do |account|
        new_scheduled_post = ScheduledPost.new( user_id: self.id,
                                                account_id: account.id,
                                                micropost_id: post.micropost_id,
                                                picture_url: get_picture_with_default_overlay(post.picture_url, post.post_time + 3.months),
                                                caption: post.caption,
                                                platform: post.platform,
                                                post_time: (post.post_time - self.current_offset) )
        new_scheduled_post.save
      end
    end
  end

  # Unfollows a topic.
  def delete_topic(topic)
    topics.delete(topic)
    posts = self.scheduled_posts.where("post_time > ? AND topic_id = ?", Time.now.getutc, topic.id)
    posts.destroy_all
  end

  def utc_to_user_time(time)
    return time + self.current_offset
  end

  def user_time_to_utc(time)
    return time - self.current_offset
  end

  def current_offset
    tz = TZInfo::Timezone.get(timezone)
    current = tz.current_period
    # current.utc_offset gives utc offset without including dst
    # current.std_offset gives offset from standard time during dst
    return current.utc_total_offset
  end

  private

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    def set_timezone_to_utc
      self.timezone = "UTC" if self.timezone == nil
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

    def valid_slug
      # make sure slug is not just a number so it doesn't clash with IDs
      if self.slug && self.slug.match('(?!^\d+$)^.+$')
        self.slug = self.slug.gsub(/[^a-zA-Z0-9]/, "_")
      else
        self.slug = self.id
      end
    end

    def create_setting
      settings = Setting.new(user_id: self.id)
      settings.save!
    end

    def follow_promo_posts
      self.follow(User.first)
    end

end

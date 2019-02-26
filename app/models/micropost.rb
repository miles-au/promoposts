class Micropost < ActiveRecord::Base
  belongs_to :user
  default_scope -> { order(created_at: :desc) }
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :content, length: { maximum: 240 }
  validates :external_url, length: {maximum: 500}
  validate  :picture_size
  validate :content_exists
  validate :valid_url
  has_many :events, dependent: :destroy
  has_many :comments, dependent: :destroy

  #attr_accessor :external_url

  self.per_page = 24

  after_save :create_event
  before_destroy :delete_notifications

  def create_event
    @event = Event.new(user_id: self.user_id, micropost_id: self.id, contribution: 'create')
    @event.save!
  end

  private

    # Validates the size of an uploaded picture.
    def picture_size
      if picture.size > 10.megabytes
        errors.add(:picture, "should be less than 10MB")
      end
    end

    def content_exists
      if picture.blank? && content.blank?
        errors[:base] << "Please include a photo or text."
      end
    end

    def valid_url
      if test_link(external_url).present?
        valid_link = test_link(external_url)
      elsif test_link("http://www.#{external_url}")
        valid_link = test_link("http://www.#{external_url}")
      elsif test_link("https://www.#{external_url}")
        valid_link = test_link("https://www.#{external_url}")
      elsif test_link("http://#{external_url}")
        valid_link = test_link("http://#{external_url}")
      end

      if valid_link
        self.update_attribute('external_url', valid_link)
      else
        errors[:base] << "Please include a full valid link."
      end
    end

    def test_link(link)
      http_errors = [
        Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError
      ]

      begin
        resp = Net::HTTP.get_response(URI.parse(link))
      rescue *http_errors
        puts "Net:HTTP Error"
      rescue Exception
        puts "Net:HTTP Exception"
      end

      if resp.is_a?(Net::HTTPSuccess)
        return link
      else
        return nil
      end

    end

    def delete_notifications
      Notification.where("notifications.category = 'comment' AND notifications.destination_id = ?", self.id).destroy_all
      Notification.where("notifications.category = 'share' AND notifications.destination_id = ?", self.id).destroy_all
    end
    
end
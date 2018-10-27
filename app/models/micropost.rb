class Micropost < ActiveRecord::Base
  belongs_to :user
  default_scope -> { order(created_at: :desc) }
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :content, length: { maximum: 140 }
  validate  :picture_size
  validate :content_exists
  has_many :events, dependent: :destroy

  self.per_page = 24

  after_save :create_event

  def create_event
    @event = Event.new(active_user_id: self.user_id, micropost_id: self.id)
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
    
end
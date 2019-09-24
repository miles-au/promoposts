class LandingPage < ApplicationRecord
	belongs_to :campaign
	mount_uploader :splash, PictureUploader
	mount_uploader :pic_one, PictureUploader
	mount_uploader :pic_two, PictureUploader
	mount_uploader :pic_three, PictureUploader
	validates :title, presence: true, length: { maximum: 75 }
	validates :headline, length: { maximum: 200 }
	validates :text_one, length: { maximum: 350 }
	validates :text_two, length: { maximum: 350 }
	validates :text_three, length: { maximum: 350 }
end

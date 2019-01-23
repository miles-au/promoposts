class Product < ApplicationRecord
	has_many :listings, dependent: :destroy
	mount_uploader :picture, PictureUploader
end

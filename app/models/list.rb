class List < ApplicationRecord
	has_many :listings, dependent: :destroy
	belongs_to :user

	validates :name, length: { maximum: 75 }
end

class List < ApplicationRecord
	has_many :listings, dependent: :destroy
	belongs_to :user
end

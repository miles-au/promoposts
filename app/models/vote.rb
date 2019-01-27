class Vote < ApplicationRecord
	belongs_to :comment
	belongs_to :user

	validates :user_id, presence: true
	
end

class Setting < ApplicationRecord
	belongs_to :user

	def self.topics_limit
		return 3
	end
end

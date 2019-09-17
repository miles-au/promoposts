class TopicRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :topic
  validate :maxed_out

  private
  	def maxed_out
  		if self.user.topics.count > Topic.topics_limit
  			errors[:base] << "You've hit the maximum number of topics."
  		end
  	end
end

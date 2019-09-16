class TopicRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :topic
  validate :maxed_out

  private
  	def maxed_out
  	end
end

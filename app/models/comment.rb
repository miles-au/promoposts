class Comment < ApplicationRecord
	has_many :votes, dependent: :destroy

	belongs_to :micropost
	belongs_to :user

	validates :user_id, presence: true
	validates :message, length: { maximum: 2500 }
	validate  :content_exists

	def points
		points = self.votes.pluck(:points)
		points.inject(0){|sum,x| sum + x }
	end

	private

	    def content_exists
	      if message.blank?
	        errors[:base] << "Comment cannot be blank."
	      end
	    end

end

class Comment < ApplicationRecord
	belongs_to :micropost
	belongs_to :user

	validates :user_id, presence: true
	validates :message, length: { maximum: 2500 }
	validate  :content_exists


	private

	    def content_exists
	      if message.blank?
	        errors[:base] << "Comment cannot be blank."
	      end
	    end

end

class Notification < ApplicationRecord
  belongs_to :user
  default_scope -> { order(created_at: :desc) }

  def destination_link
  	case self.category
  	when "share"
  		micropost = Micropost.find(self.destination_id)
  		return micropost
  	when "comment"
  		micropost = Micropost.find(self.destination_id)
  		return micropost
  	when "follow"
  		user = User.find(self.destination_id)
  		return user
  	when "other"
  		return self.url || '#'
  	else
  		return '#'
  	end
  end

end

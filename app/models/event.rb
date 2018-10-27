class Event < ApplicationRecord
	belongs_to :user, optional: true
	default_scope -> { order(created_at: :desc) }

	vendors = User.where("category=?", "vendor")
  	scope :vendors, -> { where("active_user_id in (?)", vendors.ids)}

  	attr_accessor :message

end

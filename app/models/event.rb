class Event < ApplicationRecord
	belongs_to :user, optional: true
	default_scope -> { order(created_at: :desc) }

	vendors = User.where("category=?", "vendor")
  	scope :vendors, -> { where("user_id in (?)", vendors.ids)}

  	questions = Micropost.where("category=?", "question")
  	scope :questions, -> { where("micropost_id in (?)", questions.ids)}

  	products_discussions = Micropost.where("category=?", "products_discussion")
  	scope :products_discussions, -> { where("micropost_id in (?)", products_discussions.ids)}

  	attr_accessor :message

  	self.per_page = 24

end

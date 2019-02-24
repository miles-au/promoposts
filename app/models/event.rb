class Event < ApplicationRecord
	belongs_to :user, optional: true
  	belongs_to :micropost

	default_scope -> { order(created_at: :desc) }

	vendors = User.where("category=?", "vendor")
	scope :vendors, -> { where("user_id in (?)", vendors.ids)}

	questions = Micropost.where("category=?", "question")
	scope :questions, -> { where("micropost_id in (?)", questions.ids)}

	careers = Micropost.where("category=?", "careers")
	scope :careers, -> { where("micropost_id in (?)", careers.ids)}

	attr_accessor :message

	self.per_page = 24

end

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

	digital_assets = Micropost.where("category=?", "cover_photo").or(Micropost.where("category=?", "email_banner")).or(Micropost.where("category=?", "infographic")).or(Micropost.where("category=?", "general_update")).or(Micropost.where("category=?", "meme"))
	scope :digital_assets, -> { where("micropost_id in (?)", digital_assets.ids)}

	general_updates = Micropost.where("category=?", "general_update")
	scope :general_updates, -> { where("micropost_id in (?)", general_updates.ids)}

	cover_photos = Micropost.where("category=?", "cover_photo")
	scope :cover_photos, -> { where("micropost_id in (?)", cover_photos.ids)}

	email_banners = Micropost.where("category=?", "email_banner")
	scope :email_banners, -> { where("micropost_id in (?)", email_banners.ids)}

	infographics = Micropost.where("category=?", "infographic")
	scope :infographics, -> { where("micropost_id in (?)", infographics.ids)}

	memes = Micropost.where("category=?", "meme")
	scope :memes, -> { where("micropost_id in (?)", memes.ids)}

	news = Micropost.where("category=?", "news")
	scope :news, -> { where("micropost_id in (?)", news.ids)}

	attr_accessor :message

	#self.per_page = 24

end

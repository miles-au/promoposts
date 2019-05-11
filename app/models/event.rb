class Event < ApplicationRecord
	belongs_to :user, optional: true
  	belongs_to :micropost

	default_scope -> { order(created_at: :desc) }

	#global feed
	#hides assets that are in a campaign but not the campaign poster
	global = Micropost.where(:campaign_id => nil).or(Micropost.where("category=?", "campaign"))
	scope :global, -> { where("micropost_id in (?)", global.ids)}

	#vendor feed
	#vendors = User.where("category=?", "vendor")
	#scope :vendors, -> { where("user_id in (?)", vendors.ids)}

	#questions feed
	questions = Micropost.where("category=?", "question")
	scope :questions, -> { where("micropost_id in (?)", questions.ids)}

	#careers feed
	careers = Micropost.where("category=?", "careers")
	scope :careers, -> { where("micropost_id in (?)", careers.ids)}

	#digital assets feed.
	#Hides assets that are in a campaign, but not the campaign poster
	#all assets get all digital assets
	#filters through all digital assets, and keeps ones where the campaign is nil, or it is the campaign poster
	all_assets = Micropost.where("category=?", "cover_photo").or(Micropost.where("category=?", "email_banner")).or(Micropost.where("category=?", "infographic")).or(Micropost.where("category=?", "general_update")).or(Micropost.where("category=?", "meme"))
	digital_assets = all_assets.where(:campaign_id => nil).or(Micropost.where("category=?", "campaign"))
	scope :digital_assets, -> { where("micropost_id in (?)", digital_assets.ids)}

	#campaign feed, only microposts with the category "campaign" are the posters
	campaigns = Micropost.where("category=?", "campaign")
	scope :campaigns, -> { where("micropost_id in (?)", campaigns.ids)}

	#general updates feed
	general_updates = Micropost.where("category=?", "general_update")
	scope :general_updates, -> { where("micropost_id in (?)", general_updates.ids)}

	#cover photos feed
	cover_photos = Micropost.where("category=?", "cover_photo")
	scope :cover_photos, -> { where("micropost_id in (?)", cover_photos.ids)}

	#email banners feed
	email_banners = Micropost.where("category=?", "email_banner")
	scope :email_banners, -> { where("micropost_id in (?)", email_banners.ids)}

	#infographics feed
	infographics = Micropost.where("category=?", "infographic")
	scope :infographics, -> { where("micropost_id in (?)", infographics.ids)}

	#memes feed
	memes = Micropost.where("category=?", "meme")
	scope :memes, -> { where("micropost_id in (?)", memes.ids)}

	#news feed
	news = Micropost.where("category=?", "news")
	scope :news, -> { where("micropost_id in (?)", news.ids)}

	attr_accessor :message

	#self.per_page = 24

end

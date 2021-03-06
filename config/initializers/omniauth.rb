OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
	provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
            :scope => 'public_profile, manage_pages, publish_pages, pages_show_list',
            :info_fields => 'name,email,location',
            :display => "popup",
            token_params: { parse: :json }

	#provider :instagram, ENV['INSTAGRAM_CLIENT_ID'], ENV['INSTAGRAM_CLIENT_SECRET']

	provider :buffer, ENV['BUFFER_CLIENT_ID'], ENV['BUFFER_CLIENT_SECRET']

	provider :linkedin, ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET'],
			:scope => 'r_liteprofile r_emailaddress w_member_social',
			:fields => ['id', 'first-name', 'last-name', 'picture-url', 'email-address']

	provider :twitter, ENV["TWITTER_KEY"], ENV["TWITTER_SECRET"],{
			:secure_image_url => 'true',
			:image_size => 'original',
		}

	provider :pinterest, ENV['PINTEREST_APP_ID'], ENV['PINTEREST_APP_SECRET']
end
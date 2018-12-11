OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
	provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
            :scope => 'public_profile, manage_pages, publish_pages, pages_show_list',
            :info_fields => 'name,email,location',
            :display => "popup",
            token_params: { parse: :json }

	#provider :instagram, ENV['INSTAGRAM_CLIENT_ID'], ENV['INSTAGRAM_CLIENT_SECRET']

	provider :buffer, ENV['BUFFER_CLIENT_ID'], ENV['BUFFER_CLIENT_SECRET'], token_params: { parse: :json }

 end

=begin
OAUTH1

	 provider :linkedin, ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET'],
	 		:scope => 'w_share rw_company_admin r_basicprofile ',
	 		:fields => ['id', 'first-name', 'last-name']
=end
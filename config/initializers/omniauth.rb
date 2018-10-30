OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
	provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
            :scope => 'public_profile, email, manage_pages, publish_pages, pages_show_list, user_location',
            :info_fields => 'name,email,location',
            :display => "popup",
            token_params: { parse: :json }
 end

Rails.application.config.middleware.use OmniAuth::Builder do
	 provider :linkedin, ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET'], :fields => ['id', 'first-name', 'last-name']
 end

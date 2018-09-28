Rails.application.config.middleware.use OmniAuth::Builder do
   provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
            :scope => 'default,email,manage_pages,publish_pages,pages_show_list', :display => 'popup'
 end
LinkedIn.configure do |config|
  config.client_id = ENV['LINKEDIN_CLIENT_ID']
  config.client_secret = ENV['LINKEDIN_CLIENT_SECRET']

  if Rails.env.development?
  	config.redirect_uri  = "https://d72ac182.ngrok.io/oauth2/linkedin?provider=linkedin"
  else
  	config.redirect_uri  = "https://promoposts.net/oauth2/linkedin?provider=linkedin"
  end
  
end
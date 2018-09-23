if Rails.env.production?
  CarrierWave.configure do |config|
	  config.fog_provider = 'fog/google'                        # required
	  config.fog_credentials = {
	    provider:                         'Google',
	    google_storage_access_key_id:     ENV['GOOGLE_ID'],
	    google_storage_secret_access_key: ENV['GOOGLE_SECRET']
	  }
	  config.fog_directory = 'name_of_directory'
	end

end
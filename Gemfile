source 'https://rubygems.org'
source "https://rails-assets.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.1'
gem 'httparty'
#gem 'rest-client'
gem 'bootstrap-sass'
gem 'jquery-rails'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'fog', '~> 2.0.0'
gem "fog-google"
gem 'carrierwave-google-storage'
gem "mime-types"
gem 'dotenv-rails'

#OAuth / Social platforms
gem 'omniauth'
gem 'omniauth-oauth2'
gem 'omniauth-buffer2'
gem 'omniauth-facebook'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-pinterest'
gem 'koala'
gem 'twitter'
gem 'pinterest-api'
gem 'buffer', :github => 'bufferapp/buffer-ruby'

#gem 'omniauth-instagram'
#gem "instagram", :git => 'git://github.com/Instagram/instagram-ruby-gem.git'

#gem 'ransack', github: 'activerecord-hackery/ransack'

gem "popper_js"
gem 'possessive'
gem "pg_search"
gem 'rack-attack'
gem 'rubyzip'
gem 'zip-zip'

# using heroku scheduler. Whenever doesn't work on heroku
#gem 'whenever'

gem 'lockbox'
gem 'blind_index'

gem 'tzinfo'
gem "rails-assets-jsTimezoneDetect"
gem 'prerender_rails'

# Use PG as DB
gem 'pg', '0.18.4'

# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt'

# Use ActiveStorage variant
gem 'mini_magick'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  # Use sqlite3 as the database for Active Record
  #gem 'sqlite3', '~> 1.3.6'
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'guard',                    '2.13.0'
  gem 'guard-minitest',           '2.4.4'
  gem 'rails-controller-testing'
  gem 'faker'
  #gem 'rspec-rails', '~> 3.8'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'derailed_benchmarks'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  #gem 'spring-commands-rspec'
  gem "brakeman"
  gem "traceroute"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end

group :production do

end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

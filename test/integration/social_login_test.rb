require 'test_helper'
include SessionsHelper

class SocialLoginTest < ActionController::TestCase
  def setup
    @user = users(:michael)
    @controller = SessionsController.new
  end

  def valid_facebook_login_setup
    if Rails.env.test?
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid: '105843750575357',
        info: {
          name: "Lisa Alcddiaigahbf Bushakstein",
          email: "cwjqynlhbw_1551644016@tfbnw.net"
        },
        credentials: {
          token: "EAADe1To4HxcBAMeXrFRU6PR2tZCuWPXBA5WMcm2on7TVmZCKU9ZAnZBzAEc5IniIXiLgQuAXC5q8IqynB9jBZAKU5uPElMhS7WppImtwx6ZAZAyxaE3ZBruO8SuUR0H9QuZCE5ckZBtMQZBah0I81SqL4cfLLPfFJnSk0Se60Tq2H2lEHKxeRxSZBeZBlYzKkEAWAqDswZBc1j6f3ssvfAQUNQOOZCJ",
          expires_at: Time.now + 1.week
        },
        extra: {
          raw_info: {
            gender: 'male'
          }
        }
      })
    end
  end

  test "facebook login" do
  	#tests login with Test User: Lisa Alcddiaigahbf Bushakstein
  	valid_facebook_login_setup
  	omniauth_params = {"intent" => "sign_in"}
  	request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:facebook]
  	request.env['omniauth.params'] = omniauth_params
  	get 'callback', :params => { :provider => "facebook" }
  	assert logged_in?
  end

  

end
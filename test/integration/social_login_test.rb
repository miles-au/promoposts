require 'test_helper'
include SessionsHelper
require 'uri'

class SocialLoginTest < ActionController::TestCase
  def setup
    @user = users(:michael)
    @controller = SessionsController.new

    @test_users = Koala::Facebook::TestUsers.new(app_id: ENV['FACEBOOK_KEY'], secret: ENV['FACEBOOK_SECRET'])
    @test = @test_users.create(true, ['manage_pages', 'publish_pages'])
    @test = Koala::Facebook::API.new(@test["access_token"])
  end

  def valid_facebook_login_setup
    if Rails.env.test?
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid: @test.get_object("me")['id'],
        info: {
          name: @test.get_object("me")['name'],
          email: "test_email@tfbnw.net"
        },
        credentials: {
          token: @test.access_token,
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

  def invalid_facebook_login_setup
    if Rails.env.test?
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid: '12345',
        info: {
          name: @test.get_object("me")['name'],
          email: "test_email@tfbnw.net"
        },
        credentials: {
          token: @test.access_token,
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

  test "invalid facebook login" do
    #UID doesn't match token
    invalid_facebook_login_setup
    omniauth_params = {"intent" => "sign_in"}
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:facebook]
    request.env['omniauth.params'] = omniauth_params
    get 'callback', :params => { :provider => "facebook" }
    assert_not logged_in?
  end

end
require 'test_helper'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @account = accounts(:test_page)
  end

  test "share from facebook" do
  	assert_difference ['Micropost.count', 'Event.count'] do
  		payload = {"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"name"=>"Test Page", "id"=>@account.account_id}, "post_id"=>"44444444_444444444", "item"=>"status", "verb"=>"add", "published"=>1, "created_time"=>1551573275, "message"=>"Example post content."}}], "id"=>"0", "time"=>1551573275}], "object"=>"page", "password"=>ENV['webhooks_password'], "webhook"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"name"=>"Test Page", "id"=>@account.id}, "post_id"=>"44444444_444444444", "item"=>"status", "verb"=>"add", "published"=>1, "created_time"=>1551573275, "message"=>"Example post content."}}], "id"=>"0", "time"=>1551573275}], "object"=>"page"}}
    	post facebook_webhooks_path, params: payload
    end
  end

  test "share from facebook - picture" do
  	assert_difference ['Micropost.count', 'Event.count'] do
  		payload = {"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"id"=>@account.account_id, "name"=>"Promo Posts"}, "post_id"=>"190203818526382_248192402727523", "item"=>"photo", "verb"=>"add", "link"=>"https://scontent.fyvr1-1.fna.fbcdn.net/v/t1.0-9/53117907_248192372727526_2470462134937452544_o.jpg?_nc_cat=105&_nc_ht=scontent.fyvr1-1.fna&oh=b5649800fe4ed2cb4ddb746ee1183685&oe=5CDDC26D", "published"=>1, "created_time"=>1551641475, "photo_id"=>"248192369394193", "message"=>"test photo with caption"}}], "id"=>"190203818526382", "time"=>1551641482}], "object"=>"page", "password"=>ENV['webhooks_password'], "webhook"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"id"=>"190203818526382", "name"=>"Promo Posts"}, "post_id"=>"190203818526382_248192402727523", "item"=>"photo", "verb"=>"add", "link"=>"https://scontent.fyvr1-1.fna.fbcdn.net/v/t1.0-9/53117907_248192372727526_2470462134937452544_o.jpg?_nc_cat=105&_nc_ht=scontent.fyvr1-1.fna&oh=b5649800fe4ed2cb4ddb746ee1183685&oe=5CDDC26D", "published"=>1, "created_time"=>1551641475, "photo_id"=>"248192369394193", "message"=>"test photo with caption"}}], "id"=>"190203818526382", "time"=>1551641482}], "object"=>"page"}}
    	post facebook_webhooks_path, params: payload
    end
  end

  test "share from facebook - removal" do
    assert_no_difference ['Micropost.count', 'Event.count'] do
      payload = {"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"recipient_id"=>@account.account_id, "from"=>{"id"=>@account.account_id, "name"=>"Promo Posts"}, "item"=>"post", "post_id"=>"190203818526382_248192106060886", "verb"=>"remove", "created_time"=>1551641464}}], "id"=>@account.account_id, "time"=>1551641467}], "object"=>"page", "password"=>ENV['webhooks_password'], "webhook"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"recipient_id"=>@account.id, "from"=>{"id"=>@account.id, "name"=>"Promo Posts"}, "item"=>"post", "post_id"=>"190203818526382_248192106060886", "verb"=>"remove", "created_time"=>1551641464}}], "id"=>@account.id, "time"=>1551641467}], "object"=>"page"}}
      post facebook_webhooks_path, params: payload
    end
  end

  test "share from facebook - wrong password" do
    assert_no_difference ['Micropost.count', 'Event.count'] do
      payload = {"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"name"=>"Test Page", "id"=>@account.account_id}, "post_id"=>"44444444_444444444", "item"=>"status", "verb"=>"add", "published"=>1, "created_time"=>1551573275, "message"=>"Example post content."}}], "id"=>"0", "time"=>1551573275}], "object"=>"page", "password"=>"wrong-password", "webhook"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"name"=>"Test Page", "id"=>@account.id}, "post_id"=>"44444444_444444444", "item"=>"status", "verb"=>"add", "published"=>1, "created_time"=>1551573275, "message"=>"Example post content."}}], "id"=>"0", "time"=>1551573275}], "object"=>"page"}}
      post facebook_webhooks_path, params: payload
      payload = {"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"name"=>"Test Page", "id"=>@account.account_id}, "post_id"=>"44444444_444444444", "item"=>"status", "verb"=>"add", "published"=>1, "created_time"=>1551573275, "message"=>"Example post content."}}], "id"=>"0", "time"=>1551573275}], "object"=>"page", "webhook"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"from"=>{"name"=>"Test Page", "id"=>@account.id}, "post_id"=>"44444444_444444444", "item"=>"status", "verb"=>"add", "published"=>1, "created_time"=>1551573275, "message"=>"Example post content."}}], "id"=>"0", "time"=>1551573275}], "object"=>"page"}}
      post facebook_webhooks_path, params: payload
    end
  end

end

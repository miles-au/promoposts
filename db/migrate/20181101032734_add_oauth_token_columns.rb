class AddOauthTokenColumns < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :fb_oauth_token, :string
  	add_column :users, :linkedin_oauth_token, :string
  end
end

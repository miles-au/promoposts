class AddOauthSecretToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :fb_oauth_secret, :string
  	add_column :users, :linkedin_oauth_secret, :string
  end
end

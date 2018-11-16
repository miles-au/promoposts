class RemoveOauthSecrets < ActiveRecord::Migration[5.2]
  def change
  	remove_column :users, :fb_oauth_secret
  	remove_column :users, :linkedin_oauth_secret
  end
end

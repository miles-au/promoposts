class UpdateUserColumnsForOauth < ActiveRecord::Migration[5.2]
  def change
  	remove_column :users, :oauth_expires_at
  	remove_column :users, :oauth_token
  	remove_column :users, :uid
  	remove_column :users, :provider
  	add_column :users, :fb_uid, :string
  	add_column :users, :linkedin_uid, :string
  end
end

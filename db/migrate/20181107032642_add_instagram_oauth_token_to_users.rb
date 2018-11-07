class AddInstagramOauthTokenToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :instagram_oauth_token, :string
  end
end

class AddTwitterToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :twitter_oauth_token, :string
  	add_column :users, :twitter_uid, :string
  end
end

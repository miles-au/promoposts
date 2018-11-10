class AddBufferOauthAndUidToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :buffer_oauth_token, :string
  	add_column :users, :buffer_uid, :string
  end
end

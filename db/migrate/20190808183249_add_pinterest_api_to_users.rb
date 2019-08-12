class AddPinterestApiToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :pinterest_oauth_token, :string
  	add_column :users, :pinterest_uid, :string
  end
end

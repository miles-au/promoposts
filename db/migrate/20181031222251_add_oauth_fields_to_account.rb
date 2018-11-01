class AddOauthFieldsToAccount < ActiveRecord::Migration[5.2]
  def change
  	add_column :accounts, :access_token, :string
  	add_column :accounts, :uid, :string
  	add_column :accounts, :autoshare, :boolean
  end
end

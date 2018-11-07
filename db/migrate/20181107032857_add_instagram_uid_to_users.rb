class AddInstagramUidToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :instagram_uid, :string
  end
end

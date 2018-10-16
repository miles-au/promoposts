class AddFbAutoshareToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :fb_autoshare, :string, default: [].to_yaml, array:true
  end
end

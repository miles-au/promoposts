class RenameActiveUserIdToUserIdInEvents < ActiveRecord::Migration[5.2]
  def change
  	rename_column :events, :active_user_id, :user_id
  end
end

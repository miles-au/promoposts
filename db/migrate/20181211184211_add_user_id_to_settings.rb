class AddUserIdToSettings < ActiveRecord::Migration[5.2]
  def change
  	add_column :settings, :user_id, :string
  end
end

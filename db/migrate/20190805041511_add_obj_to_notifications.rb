class AddObjToNotifications < ActiveRecord::Migration[5.2]
  def change
  	add_column :notifications, :obj, :string
  end
end

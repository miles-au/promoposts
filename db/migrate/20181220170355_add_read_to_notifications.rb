class AddReadToNotifications < ActiveRecord::Migration[5.2]
  def change
  	add_column :notifications, :read, :boolean, default: false

  	reversible do |dir|
	    dir.up { Notification.update_all('read = false') }
	  end
  end
end

class AddCategoryAndDestinationIdToNotifications < ActiveRecord::Migration[5.2]
  def change
  	add_column :notifications, :category, :string
  	add_column :notifications, :destination_id, :integer
  end
end

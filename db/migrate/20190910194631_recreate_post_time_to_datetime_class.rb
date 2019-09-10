class RecreatePostTimeToDatetimeClass < ActiveRecord::Migration[5.2]
  def change
  	remove_column :scheduled_posts, :post_time
  	add_column :scheduled_posts, :post_time, :datetime
  end
end

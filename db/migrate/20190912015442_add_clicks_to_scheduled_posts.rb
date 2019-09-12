class AddClicksToScheduledPosts < ActiveRecord::Migration[5.2]
  def change
  	add_column :scheduled_posts, :clicks, :integer, :default => 0
  end
end

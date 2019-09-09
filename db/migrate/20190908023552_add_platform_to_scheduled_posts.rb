class AddPlatformToScheduledPosts < ActiveRecord::Migration[5.2]
  def change
  	add_column :scheduled_posts, :platform, :string
  end
end

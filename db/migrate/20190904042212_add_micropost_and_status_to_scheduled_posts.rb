class AddMicropostAndStatusToScheduledPosts < ActiveRecord::Migration[5.2]
  def change
  	add_column :scheduled_posts, :micropost_id, :integer
  	add_column :scheduled_posts, :status, :string, :default => "waiting"
  end
end

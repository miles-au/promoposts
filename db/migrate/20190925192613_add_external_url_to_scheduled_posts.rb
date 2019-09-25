class AddExternalUrlToScheduledPosts < ActiveRecord::Migration[5.2]
  def change
  	add_column :scheduled_posts, :external_url, :string
  end
end

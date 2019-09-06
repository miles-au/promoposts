class AdditionsToScheduledPosts < ActiveRecord::Migration[5.2]
  def change
  	add_column :scheduled_posts, :user_id, :integer
  	add_column :scheduled_posts, :account_id, :integer
  	add_column :scheduled_posts, :picture_url, :string
  	add_column :scheduled_posts, :caption, :string
  	add_column :scheduled_posts, :post_time, :string
  end
end

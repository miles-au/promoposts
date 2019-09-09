class AddTopicToScheduledPost < ActiveRecord::Migration[5.2]
  def change
  	add_column :scheduled_posts, :topic_id, :integer
  end
end

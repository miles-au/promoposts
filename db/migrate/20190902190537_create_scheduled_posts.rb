class CreateScheduledPosts < ActiveRecord::Migration[5.2]
  def change
    create_table :scheduled_posts do |t|

      t.timestamps
    end
  end
end

class ScheduledPostTimesstampWithoutTimezone < ActiveRecord::Migration[5.2]
  def change
  	change_column :scheduled_posts, :post_time, 'timestamp without time zone'
  end
end

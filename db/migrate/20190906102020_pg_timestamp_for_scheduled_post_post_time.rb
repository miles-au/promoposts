class PgTimestampForScheduledPostPostTime < ActiveRecord::Migration[5.2]
  def change
  	def up
	    execute 'ALTER TABLE scheduled_posts ALTER COLUMN post_time TYPE timestamp without time zone USING (post_time::timestamp without time zone)'
	  end

	  def down
	    execute 'ALTER TABLE scheduled_posts ALTER COLUMN post_time TYPE text USING (post_time::text)'
	  end
  end
end

class RedoUtcOffsetColumnInUsers < ActiveRecord::Migration[5.2]
  def change
  	remove_column :users, :zone_offset
  	add_column :users, :utc_offset, :integer
  end
end

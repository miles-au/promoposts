class RenameUtcOffsetInUsers < ActiveRecord::Migration[5.2]
  def change
  	rename_column :users, :utc_offset, :zone_offset
  end
end

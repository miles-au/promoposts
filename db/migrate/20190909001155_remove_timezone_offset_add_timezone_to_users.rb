class RemoveTimezoneOffsetAddTimezoneToUsers < ActiveRecord::Migration[5.2]
  def change
  	remove_column :users, :utc_offset
  	add_column :users, :timezone, :string
  end
end

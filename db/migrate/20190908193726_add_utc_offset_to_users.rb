class AddUtcOffsetToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :utc_offset, :string
  end
end

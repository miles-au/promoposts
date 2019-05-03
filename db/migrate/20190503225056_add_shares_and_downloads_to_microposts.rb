class AddSharesAndDownloadsToMicroposts < ActiveRecord::Migration[5.2]
  def change
  	add_column :microposts, :shares, :integer
  	add_column :microposts, :downloads, :integer
  end
end

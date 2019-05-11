class AddCampaignIdToMicroposts < ActiveRecord::Migration[5.2]
  def change
  	add_column :microposts, :campaign_id, :integer
  	add_index :campaigns, [:micropost_id, :created_at]
  end
end

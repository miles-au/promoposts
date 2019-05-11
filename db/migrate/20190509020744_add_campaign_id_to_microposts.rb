class AddCampaignIdToMicroposts < ActiveRecord::Migration[5.2]
  def change
  	add_column :microposts, :campaign_id, :integer
  end
end

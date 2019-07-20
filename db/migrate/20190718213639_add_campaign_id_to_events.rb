class AddCampaignIdToEvents < ActiveRecord::Migration[5.2]
  def change
  	add_column :events, :campaign_id, :integer
  end
end

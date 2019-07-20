class AddContentToCampaigns < ActiveRecord::Migration[5.2]
  def change
  	add_column :campaigns, :content, :string
  end
end

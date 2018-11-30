class AddContributionToEvents < ActiveRecord::Migration[5.2]
  def change
  	add_column :events, :contribution, :string
  end
end

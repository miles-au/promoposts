class AddLastShareTimeToAccounts < ActiveRecord::Migration[5.2]
  def change
  	add_column :accounts, :last_share_time, :datetime
  end
end

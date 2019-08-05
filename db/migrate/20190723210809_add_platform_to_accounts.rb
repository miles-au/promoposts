class AddPlatformToAccounts < ActiveRecord::Migration[5.2]
  def change
  	add_column :accounts, :platform, :string
  end
end

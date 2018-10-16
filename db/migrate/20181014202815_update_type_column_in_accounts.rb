class UpdateTypeColumnInAccounts < ActiveRecord::Migration[5.2]
  def change
  	rename_column :accounts, :type, :provider
  end
end

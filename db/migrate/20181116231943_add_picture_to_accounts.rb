class AddPictureToAccounts < ActiveRecord::Migration[5.2]
  def change
  	add_column :accounts, :picture, :string
  end
end

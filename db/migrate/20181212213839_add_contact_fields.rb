class AddContactFields < ActiveRecord::Migration[5.2]
  def change
  	add_column :contacts, :email, :string
  	add_column :contacts, :subject, :string
  	add_column :contacts, :message, :string
  end
end

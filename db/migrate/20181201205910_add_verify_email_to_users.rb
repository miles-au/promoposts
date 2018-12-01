class AddVerifyEmailToUsers < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :verify_email, :boolean, default: false
  end
end

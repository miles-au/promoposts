class DefaultColorOnUsers < ActiveRecord::Migration[5.2]
  def change
  	change_column :users, :color, :string, :default => '#ffffff'
  end
end

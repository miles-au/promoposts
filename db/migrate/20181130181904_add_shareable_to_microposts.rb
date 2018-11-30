class AddShareableToMicroposts < ActiveRecord::Migration[5.2]
  def change
  	add_column :microposts, :source, :string
  	add_column :microposts, :shareable, :boolean, default: false
  end
end

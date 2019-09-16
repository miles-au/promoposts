class AddPictureToTopics < ActiveRecord::Migration[5.2]
  def change
  	add_column :topics, :picture, :string
  end
end

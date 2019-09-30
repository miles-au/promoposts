class AddDisabledToTopics < ActiveRecord::Migration[5.2]
  def change
  	add_column :topics, :disabled, :boolean, default: false
  end
end

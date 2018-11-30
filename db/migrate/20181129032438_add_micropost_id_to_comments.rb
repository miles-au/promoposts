class AddMicropostIdToComments < ActiveRecord::Migration[5.2]
  def change
  	add_column :comments, :micropost_id, :integer
  end
end

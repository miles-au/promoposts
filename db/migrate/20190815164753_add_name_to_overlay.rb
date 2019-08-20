class AddNameToOverlay < ActiveRecord::Migration[5.2]
  def change
  	add_column :overlays, :name, :string
  end
end

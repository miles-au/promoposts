class AddPermissionToOverlays < ActiveRecord::Migration[5.2]
  def change
  	add_column :overlays, :permissions, :string
  end
end

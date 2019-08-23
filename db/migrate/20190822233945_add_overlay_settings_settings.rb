class AddOverlaySettingsSettings < ActiveRecord::Migration[5.2]
  def change
  	add_column :settings, :default_overlay_id, :integer
  	add_column :settings, :default_overlay_location, :string
  end
end

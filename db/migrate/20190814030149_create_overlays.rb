class CreateOverlays < ActiveRecord::Migration[5.2]
  def change
    create_table :overlays do |t|
      t.integer :user_id
      t.string :picture
      t.string :category

      t.timestamps
    end
  end
end

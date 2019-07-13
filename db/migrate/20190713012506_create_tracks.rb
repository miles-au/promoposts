class CreateTracks < ActiveRecord::Migration[5.2]
  def change
    create_table :tracks do |t|
      t.integer :user_id
      t.string :category
      t.integer :asset_num
      t.string :act

      t.datetime :created_at, null: false
    end
  end
end

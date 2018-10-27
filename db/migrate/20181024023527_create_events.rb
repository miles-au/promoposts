class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.integer :active_user_id
      t.integer :passive_user_id
      t.integer :micropost_id

      t.timestamps

    end
    add_index :events, :active_user_id
    add_index :events, :passive_user_id
    add_index :events, [:active_user_id, :passive_user_id], unique: true
  end
end

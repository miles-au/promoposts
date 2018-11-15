class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.integer :user_id
      t.string :url
      t.string :picture

      t.timestamps
    end
  end
  
end

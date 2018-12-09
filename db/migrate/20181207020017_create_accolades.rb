class CreateAccolades < ActiveRecord::Migration[5.2]
  def change
    create_table :accolades do |t|
      t.integer :user_id
      t.boolean :newcomer, default: true
    end
  end
end
